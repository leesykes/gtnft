"use client";

import { useEffect, useState } from "react";
import Image from "next/image";
import { Address } from "@scaffold-ui/components";
import type { NextPage } from "next";
import { formatEther } from "viem";
import { useAccount } from "wagmi";
import { useTargetNetwork } from "~~/hooks/scaffold-eth";
import { useScaffoldContract, useScaffoldReadContract, useScaffoldWriteContract } from "~~/hooks/scaffold-eth";
import { notification } from "~~/utils/scaffold-eth";

const COLLECTION_LIMIT = 3728n;
const PER_PAGE = 12n;

type NftItem = {
  id: bigint;
  name: string;
  description: string;
  image: string;
  owner: string;
  attributes?: { trait_type: string; value: string }[];
};

const GalleryPage: NextPage = () => {
  const { address: connectedAddress } = useAccount();
  const { targetNetwork } = useTargetNetwork();
  const [nfts, setNfts] = useState<NftItem[]>([]);
  const [page, setPage] = useState(1n);
  const [loading, setLoading] = useState(true);

  const { data: price } = useScaffoldReadContract({ contractName: "GTNFT", functionName: "price" });
  const { data: totalSupply } = useScaffoldReadContract({ contractName: "GTNFT", functionName: "totalSupply" });
  const { data: contract } = useScaffoldContract({ contractName: "GTNFT" });
  const { writeContractAsync, isPending } = useScaffoldWriteContract({ contractName: "GTNFT" });

  useEffect(() => {
    const load = async () => {
      if (!contract || !totalSupply) return;
      setLoading(true);
      const items: NftItem[] = [];
      const startIndex = totalSupply - 1n - PER_PAGE * (page - 1n);
      for (let i = startIndex; i > startIndex - PER_PAGE && i >= 0n; i--) {
        try {
          const tokenId = await contract.read.tokenByIndex([i]);
          const [tokenURI, owner] = await Promise.all([
            contract.read.tokenURI([tokenId]),
            contract.read.ownerOf([tokenId]),
          ]);
          const json = JSON.parse(atob(tokenURI.substring(29)));
          items.push({ id: tokenId, owner, ...json });
        } catch {
          // skip unavailable tokens
        }
      }
      setNfts(items);
      setLoading(false);
    };
    load();
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [totalSupply, page, Boolean(contract)]);

  const handleMint = async () => {
    if (!price) return;
    try {
      await writeContractAsync({ functionName: "mintItem", value: price });
      notification.success("Minted!");
    } catch {
      notification.error("Mint failed");
    }
  };

  const remaining = COLLECTION_LIMIT - (totalSupply ?? 0n);
  const hasNext = totalSupply !== undefined && totalSupply > page * PER_PAGE;

  return (
    <div className="flex items-center flex-col grow pt-10">
      <div className="px-5 text-center">
        <h1 className="text-4xl font-bold">Gallery</h1>
        <p className="mt-2 text-base-content/70">Generative Tiling NFT — on-chain generative art</p>
        <div className="flex flex-col items-center gap-2 mt-6">
          <button
            className="btn btn-primary btn-lg"
            onClick={handleMint}
            disabled={!connectedAddress || !price || isPending}
          >
            {isPending ? <span className="loading loading-spinner" /> : null}
            Mint for {price ? (+formatEther(price)).toFixed(6) : "—"} ETH
          </button>
          <span className="text-sm text-base-content/60">
            {remaining.toString()} of {COLLECTION_LIMIT.toString()} remaining
          </span>
        </div>
      </div>

      <div className="grow bg-base-300 w-full mt-10 p-8">
        {loading ? (
          <div className="flex justify-center py-20">
            <span className="loading loading-spinner loading-lg" />
          </div>
        ) : !nfts.length ? (
          <p className="text-center py-20 text-base-content/60">No GTNFT minted yet</p>
        ) : (
          <>
            <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 xl:grid-cols-4 gap-6">
              {nfts.map(nft => (
                <div key={nft.id} className="card bg-base-100 shadow-md">
                  <figure className="pt-4 px-4">
                    <Image src={nft.image} alt={nft.name} width={300} height={300} className="rounded-xl" />
                  </figure>
                  <div className="card-body p-4 gap-1">
                    <h2 className="card-title text-base justify-center">{nft.name}</h2>
                    <div className="flex justify-center mt-1">
                      <Address address={nft.owner} chain={targetNetwork} />
                    </div>
                    {nft.attributes && (
                      <div className="flex flex-wrap gap-1 mt-2 justify-center">
                        {nft.attributes.map(attr => (
                          <span key={attr.trait_type} className="badge badge-outline badge-sm">
                            {attr.trait_type}: {attr.value}
                          </span>
                        ))}
                      </div>
                    )}
                  </div>
                </div>
              ))}
            </div>

            <div className="flex justify-center mt-8">
              <div className="join">
                {page > 1n && (
                  <button className="join-item btn" onClick={() => setPage(p => p - 1n)}>
                    «
                  </button>
                )}
                <button className="join-item btn btn-disabled">Page {page.toString()}</button>
                {hasNext && (
                  <button className="join-item btn" onClick={() => setPage(p => p + 1n)}>
                    »
                  </button>
                )}
              </div>
            </div>
          </>
        )}
      </div>
    </div>
  );
};

export default GalleryPage;
