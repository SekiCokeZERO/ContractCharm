//SPDX-License-Identifier: UNLICENSED
pragma solidity =0.8.25;

//编译时请检查 compiler_config.json 中的 evmVersion 以避免造成兼容性问题
contract Factory {
    address immutable _owner = msg.sender;
    bytes constant _loaderBytecode =
        hex"608080604052346100ea576352c7420d60e01b81526000908181600481335afa9182156100de578092610035575b825160208401f35b3d9250908282823e61004683610105565b8281019260208091126100da5781516001600160401b03928382116100d65785609f830112156100d6578101519283116100d15760405194610092601f8501601f19166020018761012b565b83865260a084830101116100cd57835b8381106100b957505050820160200152388061002d565b81810160a0015186820184015282016100a2565b8380fd5b6100ef565b8480fd5b8280fd5b604051903d90823e3d90fd5b600080fd5b634e487b7160e01b600052604160045260246000fd5b6080601f91909101601f19168101906001600160401b038211908210176100d157604052565b601f909101601f19168101906001600160401b038211908210176100d15760405256fe";
    bytes private _bytecode = hex"01";

    //必须传入无 constructor 合约的 Runtime Bytecode, 否则所创建的合约将不可用; 欲创建的合约必须预留 selfdestruct, 否则后续将无法进行升级
    function setBytecode(bytes memory bytecode) external {
        require(msg.sender == _owner, "PERMISSION_DENIED");
        _bytecode = bytecode;
    }

    function getBytecode() external view returns (bytes memory) {
        return _bytecode;
    }

    function deploy(uint256 salt) external {
        require(msg.sender == _owner, "PERMISSION_DENIED");
        require(_bytecode.length > 1, "EMPTY_BYTECODE");
        require(
            _isNoCode(_calculateCreate2Address(_loaderBytecode, salt)),
            "ALREADY_DEPLOYED"
        );

        bytes memory loaderBytecode = _loaderBytecode;
        assembly {
            pop(
                create2(
                    callvalue(),
                    add(0x20, loaderBytecode),
                    mload(loaderBytecode),
                    salt
                )
            )
        }
    }

    function _calculateCreate2Address(bytes memory bytecode, uint256 salt)
        internal
        view
        returns (address)
    {
        bytes32 hash = keccak256(
            abi.encodePacked(
                bytes1(0xff),
                address(this),
                salt,
                keccak256(bytecode)
            )
        );
        return address(uint160(uint256(hash)));
    }

    function _isNoCode(address account) internal view returns (bool) {
        uint256 codeSize;
        assembly {
            codeSize := extcodesize(account)
        }
        return codeSize == 0;
    }
}

//Loader 编译后的 Creation Bytecode 即为 _loaderBytecode
contract Loader {
    constructor() {
        bytes memory bytecode = Factory(msg.sender).getBytecode();
        assembly {
            return(add(bytecode, 0x20), mload(bytecode))
        }
    }
}