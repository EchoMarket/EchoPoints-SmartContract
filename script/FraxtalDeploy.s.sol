// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

import {Script} from "forge-std/Script.sol";
import {console2} from "forge-std/console2.sol";

import {EchoPoints} from "../contracts/EchoPoints.sol";

contract FraxtalDeploy is Script {
    // NOTE: Settled By Product Owner.
    address public constant PROTOCOL_ADMIN =
        0x87DF94c894983cC2977b760d1587A0cC21284EdC;

    uint256 constant FRAXTAL_MAINNET = 252;
    uint256 constant FRAXTAL_TESTNET = 2522;

    function run() public {
        if (
            block.chainid != FRAXTAL_MAINNET && block.chainid != FRAXTAL_TESTNET
        ) revert("Invalid Fraxtal Network!");

        vm.startBroadcast(vm.envUint("PRIVATE_KEY"));
        EchoPoints echoPoints = new EchoPoints(PROTOCOL_ADMIN);
        vm.stopBroadcast();

        console2.log("Echo Points: ", address(echoPoints));
    }
}
