//SPDX-License-Identifier: Unlicense

interface ITokenTvT {
  function getIssuanceSwapRatio() external view returns (uint256);

  function matureBalanceOf(address subscriber)
    external
    view
    returns (uint256 result);

  function matureBalanceOfPending(address subscriber)
    external
    view
    returns (uint256 result);

  function redeem(address subscriber, uint256 value) external;

  function redeem(
    address subscriber,
    address paymentTokenDestination,
    address tradeTokenDestination,
    uint256 value
  ) external;
}
