// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import "forge-std/Test.sol";
import "../src/Bridge.sol";
import "../src/TestToken.sol";

contract BridgeTest is Test {
    event BridgeIn(
        address indexed operator,
        address indexed token,
        uint256 amount
    );

    event BridgeOut(
        address indexed receiver,
        address indexed token,
        uint256 amount
    );

    TestToken public tt;
    Bridge public bridge;

    function setUp() public {
        bridge = new Bridge();
        tt = new TestToken();

        deal(address(tt), address(this), 1e26);
        IERC20(tt).approve(address(bridge), 1e26);
    }

    function testSupportNewToken() public {
        assertEq(bridge.isSupported(address(tt)), false);
        bridge.supportNewToken(address(tt));
        assertEq(bridge.isSupported(address(tt)), true);
    }

    function testAddReserve() public {
        bridge.supportNewToken(address(tt));
        assertEq(bridge.reserve(address(tt)), 0);
        bridge.addReserve(address(tt), 100 ether);
        assertEq(bridge.reserve(address(tt)), 100 ether);
    }

    function testBridgeIn() public {
        bridge.supportNewToken(address(tt));
        bridge.addReserve(address(tt), 100 ether);

        vm.expectEmit();
        emit BridgeIn(address(this), address(tt), 10 ether);

        bridge.bridgeIn(address(tt), 10 ether);
        assertEq(bridge.reserve(address(tt)), 90 ether);
    }

    function testBridgeOut() public {
        bridge.supportNewToken(address(tt));
        bridge.addReserve(address(tt), 100 ether);

        vm.expectEmit();
        emit BridgeOut(address(1), address(tt), 1 ether);

        bridge.bridgeOut(address(tt), 1 ether, address(1));
        assertEq(bridge.reserve(address(tt)), 99 ether);
    }
}
