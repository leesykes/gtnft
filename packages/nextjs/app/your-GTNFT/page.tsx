"use client";

import { useEffect, useState } from "react";
import Image from "next/image";
import type { NextPage } from "next";
import { formatEther } from "viem";
import { useAccount } from "wagmi";
import { useScaffoldContract, useScaffoldReadContract, useScaffoldWriteContract } from "~~/hooks/scaffold-eth";
import { notification } from "~~/utils/scaffold-eth";

const COLLECTION_LIMIT = 3728n;

type NftItem = {
  id: bigint;
  name: string;
  description: string;
  image: string;
  attributes?: { trait_type: string; value: string }[];
};

const YourCollectionPage: NextPage = () => {
  const { address: connectedAddress } = useAccount();
  const [nfts, setNfts] = useState<NftItem[]>([]);
  const [loading, setLoading] = useState(true);

  const { data: price } = useScaffoldReadContract({ contractName: "GTNFT", functionName: "price" });
  const { data: totalSupply } = useScaffoldReadContract({ contractName: "GTNFT", functionName: "totalSupply" });
  const { data: balance } = useScaffoldReadContract({
    contractName: "GTNFT",
    functionName: "balanceOf",
    args: [connectedAddress],
  });
  const { data: contract } = useScaffoldContract({ contractName: "GTNFT" });
  const { writeContractAsync, isPending } = useScaffoldWriteContract({ contractName: "GTNFT" });

  useEffect(() => {
    const load = async () => {
      if (!contract || !balance || !connectedAddress) {
        setLoading(false);
        return;
      }
      setLoading(true);
      const items: NftItem[] = [];
      for (let i = 0n; i < balance; i++) {
        try {
          const tokenId = await contract.read.tokenOfOwnerByIndex([connectedAddress, i]);
          const tokenURI = await contract.read.tokenURI([tokenId]);
          const json = JSON.parse(atob(tokenURI.substring(29)));
          items.push({ id: tokenId, ...json });
        } catch {
          // skip unavailable tokens
        }
      }
      setNfts(items);
      setLoading(false);
    };
    load();
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [balance, connectedAddress, Boolean(contract)]);

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

  return (
    <div className="flex items-center flex-col grow pt-10">
      <div className="px-5 text-center">
        <h1 className="text-4xl font-bold">My Collection</h1>
        <p className="mt-2 text-base-content/70">
          {connectedAddress
            ? `You own ${balance?.toString() ?? "0"} GTNFT`
            : "Connect your wallet to view your collection"}
        </p>
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
        {!connectedAddress ? (
          <p className="text-center py-20 text-base-content/60">Connect your wallet to see your NFTs</p>
        ) : loading ? (
          <div className="flex justify-center py-20">
            <span className="loading loading-spinner loading-lg" />
          </div>
        ) : !nfts.length ? (
          <p className="text-center py-20 text-base-content/60">You don&apos;t own any GTNFT yet — mint one above!</p>
        ) : (
          <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 xl:grid-cols-4 gap-6">
            {nfts.map(nft => (
              <div key={nft.id} className="card bg-base-100 shadow-md">
                <figure className="pt-4 px-4">
                  <Image src={nft.image} alt={nft.name} width={300} height={300} className="rounded-xl" />
                </figure>
                <div className="card-body p-4 gap-1">
                  <h2 className="card-title text-base justify-center">{nft.name}</h2>
                  <p className="text-sm text-center text-base-content/70">{nft.description}</p>
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
        )}
      </div>
    </div>
  );
};

export default YourCollectionPage;
