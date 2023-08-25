## 简介
ContractCharm 是一款使用 CREATE2 + SELFDESTRUCT 部署可升级合约的简易工具

## 使用流程及原理
- 用户调用 Factory 合约中 setBytecode(bytes) 方法将欲创建合约的 Runtime Bytecode 写入 storage
- 用户调用 Factory 合约中 deploy(uint256) 方法将自定义 salt 与 不变的 Loader 合约 Creation ByteCode 传入 CREATE2
- 在 CREATE2 执行过程中 Loader 合约 Creation ByteCode 加载 Factory 合约中先前写入的 Runtime Bytecode 并返回
- 由于 CREATE2 使用的 Creation ByteCode 不变, 在原合约 selfdestruct 后用户使用相同的 salt 即可不更换地址更新 Runtime Bytecode

## 注意事项
- 用户调用 Factory 合约中 setBytecode(bytes) 方法时必须传入**无 constructor** 合约的 **Runtime Bytecode**, 否则所创建的合约将不可用
- 欲创建的合约必须预留 selfdestruct, 否则后续将无法进行升级

## 参考
- https://ethereum.stackexchange.com/questions/76334/what-is-the-difference-between-bytecode-init-code-deployed-bytecode-creation
- https://ctf-wiki.org/blockchain/ethereum/attacks/create2/
