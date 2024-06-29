//SPDX-License-Identifier: UNLICENSED
pragma solidity =0.8.26;

//Compatibility: EVM Version >= London
contract Factory {
    address constant _owner = INPUT_OWNER_ADDRESS_DIRECTLY;

    bytes32 constant _loader_0_1 = 0x6080604052346036576352c7420d60e01b600090815280600481335afa156036;
    bytes32 constant _loader_1_1 = 0x573d156036573d601f1901602060003e6000516020f35b600080fdfe00000000;

    bytes private _bytecode; //slot0
    bytes32 constant _bytecodeExpandSlot = 0x290decd9548b62a8d60345a988386fc84ba6bc95484008f6362f93160ef3e563;

    function initBytecode() external {
        assembly {
            if sub(caller(), _owner) {
                mstore(0x00, 0x08c379a000000000000000000000000000000000000000000000000000000000)
                mstore(0x04, 0x0000000000000000000000000000000000000000000000000000000000000020)
                mstore(0x24, 0x0000000000000000000000000000000000000000000000000000000000000011)
                mstore(0x44, 0x5045524d495353494f4e5f44454e494544000000000000000000000000000000) //PERMISSION_DENIED
                revert(0x00, 0x64)
            }
        }

        assembly {
            let length := sub(calldatasize(), 0x04)

            switch gt(length, 0x1f)
            case 1 { //length >= 32 bytes
                sstore(_bytecode.slot, add(mul(length, 2), 1)) //write length
                let iter := add(div(length, 0x20), gt(mod(length, 0x20), 0))
                for { let i } lt(i, iter) { i := add(i, 0x01) } {
                    sstore(add(_bytecodeExpandSlot, i), calldataload(add(0x04, mul(0x20, i))))
                }
            }
            default { //length <= 31 bytes
                mstore(0x00, calldataload(0x04))
                mstore8(0x1f, mul(length, 2))
                sstore(_bytecode.slot, mload(0x00))
            }
        }
    }
    function getBytecode() external view { //0x52c7420d
        assembly {
            let slotContent := sload(_bytecode.slot)

            switch mod(slotContent, 0x02)
            case 1 { //length >= 32 bytes
                let length := div(sub(slotContent, 1), 2)
                let iter := add(div(length, 0x20), gt(mod(length, 0x20), 0))
                
                mstore(0x00, 0x0000000000000000000000000000000000000000000000000000000000000020) //offset
                mstore(0x20, length)

                for { let i } lt(i, iter) { i := add(i, 0x01) } {
                    mstore(add(0x40, mul(i, 0x20)), sload(add(_bytecodeExpandSlot, i)))
                }
                return(0x00, add(0x40, mul(0x20, iter)))
            }
            default { //length <= 31 bytes
                mstore(0x00, 0x0000000000000000000000000000000000000000000000000000000000000020) //offset
                mstore(0x20, div(shr(248, shl(248, slotContent)), 2)) //length = slotContentLastByte / 2
                mstore(0x40, shl(8, shr(8, slotContent))) //value
                return(0x00, 0x60)
            }
        }
    }

    function deploy(bytes32 salt) external { //Deploy bytecode from storage
        assembly {
            if sub(caller(), _owner) {
                mstore(0x00, 0x08c379a000000000000000000000000000000000000000000000000000000000)
                mstore(0x04, 0x0000000000000000000000000000000000000000000000000000000000000020)
                mstore(0x24, 0x000000000000000000000000000000000000000000000000000000000000000e)
                mstore(0x44, 0x454d5054595f42595445434f4445000000000000000000000000000000000000) //PERMISSION_DENIED
                revert(0x00, 0x64)
            }
        }

        assembly {
            mstore(0x00, _loader_0_1)
            mstore(0x20, _loader_1_1)

            pop(
                create2(
                    0x00,
                    0x00,
                    0x3c, //60 bytes
                    salt
                )
            )
        }
    }
    function deploy() external { //Deploy bytecode from calldata
        assembly {
            if sub(caller(), _owner) {
                mstore(0x00, 0x08c379a000000000000000000000000000000000000000000000000000000000)
                mstore(0x04, 0x0000000000000000000000000000000000000000000000000000000000000020)
                mstore(0x24, 0x0000000000000000000000000000000000000000000000000000000000000011)
                mstore(0x44, 0x5045524d495353494f4e5f44454e494544000000000000000000000000000000) //PERMISSION_DENIED
                revert(0x00, 0x64)
            }
        }

        assembly {
            let length := sub(calldatasize(), 0x24)

            switch gt(length, 0x1f)
            case 1 { //length >= 32 bytes
                sstore(_bytecode.slot, add(mul(length, 2), 1)) //write length
                let iter := add(div(length, 0x20), gt(mod(length, 0x20), 0))
                for { let i } lt(i, iter) { i := add(i, 0x01) } {
                    sstore(add(_bytecodeExpandSlot, i), calldataload(add(0x24, mul(0x20, i))))
                }
            }
            default { //length <= 31 bytes
                mstore(0x00, calldataload(0x24))
                mstore8(0x1f, mul(length, 2))
                sstore(_bytecode.slot, mload(0x00))
            }
        }

        assembly {
            mstore(0x00, _loader_0_1)
            mstore(0x20, _loader_1_1)

            pop(
                create2(
                    0x00,
                    0x00,
                    0x3c, //60 bytes
                    calldataload(0x04) //salt
                )
            )
        }
    }
}

contract Loader {
    //London: 0x6080604052346036576352c7420d60e01b600090815280600481335afa156036573d156036573d601f1901602060003e6000516020f35b600080fdfe
    constructor() {
        assembly {
            mstore(0x00, 0x52c7420d00000000000000000000000000000000000000000000000000000000) //getBytecode()

            if iszero(staticcall(gas(), caller(), 0x00, 0x04, 0x00, 0x00)) {
                revert(0x00, 0x00)
            }
            if iszero(returndatasize()) {
                revert(0x00, 0x00)
            }
            
            returndatacopy(0x00, 0x20, sub(returndatasize(), 0x20))
            return(0x20, mload(0x00))
        }
    }
}