import {GaslessPayrollAbi} from '../abi/GaslessPayrollAbi';
import {createPublicClient,createWalletClient,http,custom} from 'viem';
import {sepolia} from 'viem/chains';


const PAYROLL_ADDRESS = '0xA49a53FdDA78541CcaC01e717aE95b074A1AF77a'; 
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


export async function signEmployeePay(
    employeeId: `0x${string}`,
    amount: bigint,
    month: string,
    nonce: bigint,
    deadline: bigint
){
    try{
        const walletClient = getWalletClient();
        const [address] = await walletClient.requestAddresses();
       
        const hrManager = await publicClient.readContract({
    address: PAYROLL_ADDRESS,
    abi: GaslessPayrollAbi,
    functionName: 'hrManager',
}) as `0x${string}`;

console.log("HR MANAGER FROM CONTRACT:", hrManager);
        if(address.toLowerCase() !== hrManager.toLowerCase()){
            return{
                success: false,
                error:'Connected wallet is not the HR manager',
            };
        }
        
        const signature = await walletClient.signTypedData({
            account: address,
            domain: {
                name: 'GaslessPayrollSystem',
                version: '1',
                chainId: 11155111,
                verifyingContract: PAYROLL_ADDRESS,
            },
            types: {
                EmployeePay:[
                    { name: 'employeeId', type: 'address' },
                    { name: 'amount', type: 'uint256' },
                    { name: 'month', type: 'string' },
                    { name: 'nonce', type: 'uint256' },
                    { name: 'deadline', type: 'uint256' },
                ],
            },
            primaryType: 'EmployeePay',
            message:{
                employeeId,
                amount,
                month,
                nonce,
                deadline,
            },
        });
        return { success: true, signature};
    } catch (error){
        return {
            success: false,
            error: error instanceof Error ? error.message : String(error)
       
    };
    }
}



export async function claimSalary(
    employeeId: `0x${string}`,
    amount: bigint,
    month: string,
    nonce: bigint,
    deadline: bigint,
    signature: `0x${string}`
){
    try{
        const walletClient = getWalletClient();
        const [address] = await walletClient.requestAddresses();
        const {request} = await publicClient.simulateContract({
            address: PAYROLL_ADDRESS,
            abi: GaslessPayrollAbi,
            functionName: 'claimSalary',
            args: [employeeId,amount,month,nonce,deadline,signature],
            account: address,
        })
         const hash = await walletClient.writeContract(request);
        const receipt = await publicClient.waitForTransactionReceipt({
            hash,
            confirmations: 1
        })
        return {success: receipt.status === 'success', hash,receipt};
    } catch (error){
         return {
            success: false,
            error: error instanceof Error ? error.message : String(error)
        };
    }

}