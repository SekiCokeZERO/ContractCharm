

## 单交易部署(推荐)
```solidity
775c300cc //deploy()
0000000000000000000000000000000000000000000000000000000000000000 //Salt
365f5f375f5f365f73bebebebebebebebebebebebebebebebebebebebe5af43d5f5f3e5f3d91602a57fd5bf3 //Runtime Bytecode
```
| 版本 |部署 WETH9 花费 Gas|
|:---: |:---:              |
|Cancun|762712             |
|London|2940473            |
- 单交易部署与多交易部署在写入 Runtime Bytecode 时使用相同的 Slot, 因此对于 London 版本合约, 执行单交易部署将覆盖 Slot 的内容

## 多交易部署
```solidity
ad77be5e //initBytecode()
365f5f375f5f365f73bebebebebebebebebebebebebebebebebebebebe5af43d5f5f3e5f3d91602a57fd5bf3 //Runtime Bytecode
```
```solidity
2b85ba38 //deploy(bytes32)
0000000000000000000000000000000000000000000000000000000000000000 //Salt
```
- **对于 Cancun 版本合约, 多交易部署将无法使用 TSTORE && TLOAD 操作码优化 Gas 消耗, 因此除特殊需求外建议一律使用单交易部署**

## Salt 计算
推荐配合 ERADICATE2 计算 Salt 使用
```solidity
0x6080604052346036576352c7420d60e01b600090815280600481335afa156036573d156036573d601f1901602060003e6000516020f35b600080fdfe //Loader Creation Bytecode
```
- 为保证 Salt 通用, 不同版本的 Loader Creation Bytecode 均一致(London)

## 注意事项
- ContractCharm 使用大量**内联汇编**优化 Gas 消耗, 因此在**变更 Solidity 或 EVM 版本**时应**充分测试**再部署至生产环境, 以避免预料外的行为
- 请根据 EVM 版本选择 ContractCharm, **在 Cancun 版本中使用了 TSTORE && TLOAD 操作码优化 Gas 消耗**
- 用户在写入 Runtime Bytecode 时需注意**欲部署合约的 constructor 将不会被包含或执行**
- 后续若需升级合约, 所创建的合约必须**预留 SELFDESTRUCT 且 EVM 尚未合并 EIP-6780**

## 原理
- 将 Runtime Bytecode 写入 Storage
- 将 Loader 合约的 Creation Bytecode 作为参数传入 CREATE2 并执行, 执行过程中将获取 Factory 合约中先前写入的 Runtime Bytecode 并创建合约
- 由于 CREATE2 固定使用 Loader 合约的 Creation Bytecode, 因此即使 Runtime Bytecode 不同, 也无需变更计算 Salt 的参数

## 相关链接
- https://etherscan.io/address/0xc02aaa39b223fe8d0a0e5c4f27ead9083c756cc2#code
- https://ethereum.stackexchange.com/questions/76334/what-is-the-difference-between-bytecode-init-code-deployed-bytecode-creation
- https://ctf-wiki.org/blockchain/ethereum/attacks/create2/
- https://github.com/johguse/ERADICATE2
- https://eips.ethereum.org/EIPS/eip-6780
