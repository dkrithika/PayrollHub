import {VestingTokenAbi} from '../abi/VestingTokenAbi';
import {createPublicClient,createWalletClient,http,custom} from 'viem';
import {sepolia} from 'viem/chains';


const VESTING_ADDRESS = '0xa24dA5c073E9e8Abd482D21D35f2Fc0B4680936b';
const publicClient = createPublicClient({
    chain: sepolia,
    transport: http(),
});

function getWalletClient() {
    if(!window.ethereum){
        throw new Error("MetaMask is not installed");
    }
    return createWalletClient({
        chain: sepolia,
        transport: custom(window.ethereum),
    });
}

export async  function connectWallet(){
    const walletClient = getWalletClient();
    const [address] = await walletClient.requestAddresses();
    return address;
}

export async function getVestingSchedule(
    executiveId: `0x${string}`
){
    return await publicClient.readContract({
        address: VESTING_ADDRESS,
        abi: VestingTokenAbi,
        functionName: 'getVestingSchedule',
        args: [executiveId],
    });
}

export async function enterOrganisation(
    executiveId: `0x${string}`,
    vestingDuration: bigint,
    cliffDuration: bigint,
    totalAmount: bigint
){
    try{
        // Read current state
        const walletClient = getWalletClient();
        //Connect/request the user's MetaMAsk account
        const [address] = await walletClient.requestAddresses();
        const schedule = await publicClient.readContract({
            address: VESTING_ADDRESS,
            abi: VestingTokenAbi,
            functionName: 'vestingSchedules',
            args: [executiveId]
        })
        if(schedule[7]){
            return { 
                success: false, 
                error: 'Already in organisation'};
        }

        //simulate
        const {request} = await publicClient.simulateContract({
            address: VESTING_ADDRESS,
            abi: VestingTokenAbi,
            functionName: 'enterOrganisation',
            args: [executiveId,vestingDuration,cliffDuration,totalAmount],
            account:address
        })
        //write
        const hash = await walletClient.writeContract(request);
        //wait
        const receipt = await publicClient.waitForTransactionReceipt({
            hash,
            confirmations: 1
        })
        return { success: receipt.status === 'success',hash,receipt};
    
    }
    catch (error){
        return { success: false, error: error instanceof Error ? error.message : String(error)};
    }
}

export async function claim(executiveId: `0x${string}`){
    try{
        const walletClient = getWalletClient();
        const [address] = await walletClient.requestAddresses();
        const schedule = await publicClient.readContract({
             address: VESTING_ADDRESS,
            abi: VestingTokenAbi,
            functionName: 'getVestingSchedule',
             args: [executiveId],
        });
         if(!schedule.isActive){
            return { 
                success: false, 
                error: 'You are not in the organisation'};
        }

        const {request} = await publicClient.simulateContract({
            address: VESTING_ADDRESS,
            abi: VestingTokenAbi,
            functionName: 'claim',
            args: [executiveId],
            account: address,
        });

        const hash = await walletClient.writeContract(request);
        const receipt = await publicClient.waitForTransactionReceipt({
            hash,
            confirmations: 1
        })
        return {success: receipt.status === 'success', hash,receipt};
    } catch (error){
        return {
            success: false,
            error:error instanceof Error ? error.message : String(error)
        };
    }
}

export async function clawback(executiveId: `0x${string}`){
    try{
        const walletClient = getWalletClient();
        const [address] = await walletClient.requestAddresses();

        const schedule = await publicClient.simulateContract({
            address: VESTING_ADDRESS,
            abi: VestingTokenAbi,
            functionName: 'clawback',
            args: [executiveId],
            account: address,
        });

        const hash = await walletClient.writeContract(schedule.request);
        const receipt = await publicClient.waitForTransactionReceipt({
            hash,
            confirmations: 1
        })
        return { success: receipt.status === 'success', hash, receipt };
    } catch (error) {
        return {
            success: false,
            error: error instanceof Error ? error.message : String(error)
        };
    }
}
