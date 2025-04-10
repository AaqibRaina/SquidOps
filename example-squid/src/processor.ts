import {
    BlockHeader,
    DataHandlerContext,
    EvmBatchProcessor,
    EvmBatchProcessorFields,
    Log as _Log,
    Transaction as _Transaction,
} from '@subsquid/evm-processor'
import {Store} from '@subsquid/typeorm-store'
import * as erc20 from './abi/erc20'

if (!process.env.CHAIN_RPC) {
    throw new Error('CHAIN_RPC environment variable is not set')
}

if (!process.env.CONTRACT_ADDRESS) {
    throw new Error('CONTRACT_ADDRESS environment variable is not set')
}

export const CONTRACT_ADDRESS = process.env.CONTRACT_ADDRESS

export const processor = new EvmBatchProcessor()
    .setGateway('https://v2.archive.subsquid.io/network/ethereum-mainnet')
    .setRpcEndpoint({
        url: process.env.CHAIN_RPC,
        rateLimit: 10
    })
    .setFinalityConfirmation(75)
    .setFields({
        log: {
            topics: true,
            data: true,
        },
        transaction: {
            hash: true,
        },
    })
    .addLog({
        range: {from: 6_082_465},
        address: [CONTRACT_ADDRESS],
        topic0: [erc20.events.Transfer.topic],
        transaction: true,
    })

export type Fields = EvmBatchProcessorFields<typeof processor>
export type Context = DataHandlerContext<Store, Fields>
export type Block = BlockHeader<Fields>
export type Log = _Log<Fields>
export type Transaction = _Transaction<Fields>
