//SPDX-License-Identifier: UNLICENSED
pragma solidity =0.8.22;

//编译时请检查 compiler_config.json 中的 evmVersion 以避免造成兼容性问题
contract Factory {
    address immutable _owner;
    bytes constant _loaderBytecode =
        hex"608080604052346100e9576352c7420d60e01b81526000908181600481335afa9182156100dd578092610035575b825160208401f35b9091503d8082843e61004681610104565b8083019260208092126100d95780516001600160401b03918282116100d55785609f830112156100d5578101519182116100d05760405194610091601f8401601f191685018761012a565b82865260a083830101116100cc5782845b8381106100b75750505083010152388061002d565b60a081840101518282890101520183906100a2565b8380fd5b6100ee565b8480fd5b8280fd5b604051903d90823e3d90fd5b600080fd5b634e487b7160e01b600052604160045260246000fd5b6080601f91909101601f19168101906001600160401b038211908210176100d057604052565b601f909101601f19168101906001600160401b038211908210176100d05760405256fe";

    bytes private _bytecode;

    constructor() {
        _owner = msg.sender;
    }

    function deploy(uint256 salt) external {
        require(msg.sender == _owner, "PERMISSION_DENIED");
        require(_bytecode.length > 0, "EMPTY_BYTECODE");
        require(
            _isNoCode(_calculateAddress(_loaderBytecode, salt)),
            "ALREADY_DEPLOYED"
        );

        bytes memory loaderBytecode = _loaderBytecode; //内联汇编不支持直接调用常量
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

    //必须传入无 constructor 合约的 Runtime Bytecode, 否则所创建的合约将不可用; 欲创建的合约必须预留 selfdestruct, 否则后续将无法进行升级
    function setBytecode(bytes memory bytecode) external {
        require(msg.sender == _owner, "PERMISSION_DENIED");
        _bytecode = bytecode;
    }

    function getBytecode() external view returns (bytes memory) {
        return _bytecode;
    }

    function _calculateAddress(bytes memory bytecode, uint256 salt)
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
        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size == 0;
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
