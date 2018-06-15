pragma solidity ^0.4.16;

interface token {
    function transfer(address receiver, uint amount);
}

contract Crowdsale {
    address public beneficiary;  // 募资成功后的收款方
    uint public fundingGoal;   // 募资额度
    uint public amountRaised;   // 参与数量
    uint public deadline;      // 募资截止期

    uint public price;    //  token 与以太坊的汇率 , token卖多少钱
    token public tokenReward;   // 要卖的token

    mapping(address => uint256) public balanceOf;

    bool public fundingGoalReached = false;  // 众筹是否达到目标
    bool public crowdsaleClosed = false;   //  众筹是否结束

    /**
    * 事件可以用来跟踪信息
    **/
    event GoalReached(address recipient, uint totalAmountRaised);
    event FundTransfer(address backer, uint amount, bool isContribution);
    event LogAmount(uint amount);

    /**
     * 构造函数, 设置相关属性
     */
    function Crowdsale(
        address ifSuccessfulSendTo,
        uint fundingGoalInEthers,
        uint durationInMinutes,
        uint weiCostOfEachToken,
        address addressOfTokenUsedAsReward) {
            beneficiary = ifSuccessfulSendTo;
            fundingGoal = fundingGoalInEthers * 1 ether;
            deadline = now + durationInMinutes * 1 minutes;
            /*一个TOKEN等同于1个以太坊ETH太贵了，修改官网代码，变为一个TOKEN等同于1个wei*/
            /*price = etherCostOfEachToken * 1 ether;*/
            price = weiCostOfEachToken * 1 wei;
            tokenReward = token(addressOfTokenUsedAsReward);   // 传入已发布的 token 合约的地址来创建实例
    }

    /**
     * 无函数名的Fallback函数，
     * 在向合约转账时，这个函数会被调用
     */
    function () payable {
        require(!crowdsaleClosed);
        uint amount = msg.value;
        balanceOf[msg.sender] += amount;
        amountRaised += amount;
        LogAmount(amount);/*打款3个ETH，判断此处是3还是3*10^18*/
        /*官网这个代码有问题，导致打回的币的数量会非常小，此处*1000倍，表示
          1个ETH等于1000个TOKEN/
        /*tokenReward.transfer(msg.sender, amount / price);*/
        tokenReward.transfer(msg.sender, 1000 * (amount / price));
        /*msg.sender对应的是当前运行的外部账号的地址*/
        FundTransfer(msg.sender, amount, true);
    }

    /**
    *  定义函数修改器modifier（作用和Python的装饰器很相似）
    * 用于在函数执行前检查某种前置条件（判断通过之后才会继续执行该方法）
    * _ 表示继续执行之后的代码
    **/
    modifier afterDeadline() { if (now >= deadline) _; }

    /**
     * 判断众筹是否完成融资目标， 这个方法使用了afterDeadline函数修改器
     * 此段代码不会在deadline后自动运行，而是需要在deadline时间到后人工点击执行
     * 如果在deadline时间前人工点击，会中断，也不会执行函数体代码；
     */
    function checkGoalReached() afterDeadline {
        if (amountRaised >= fundingGoal) {
            fundingGoalReached = true;
            GoalReached(beneficiary, amountRaised);
        }
        crowdsaleClosed = true;
    }


    /**
     * 完成融资目标时，融资款发送到收款方
     * 未完成融资目标时，执行退款
     * 此段代码不会在deadline后自动运行，而是在deadline时间到后人工点击执行
     * 如果在deadline时间前人工点击，会中断，也不会执行函数体代码；
     */
    function safeWithdrawal() afterDeadline {
        /*众筹截止时间后，如果众筹目标没有达到，则执行退款到当前外部账号*/
        /*官网的这段代码的健壮性不够，要使合约的执行逻辑合理，则需要需要保持当前账号为众筹打ETH的账号*/
        if (!fundingGoalReached) {
            uint amount = balanceOf[msg.sender];
            balanceOf[msg.sender] = 0;
            if (amount > 0) {
                if (msg.sender.send(amount)) {
                    FundTransfer(msg.sender, amount, false);
                } else {
                    balanceOf[msg.sender] = amount;
                }
            }
        }
        /*如果众筹目标达到了，并且受益账号等同于当前账号，则把众筹到的ETH打给当前账号*/
        if (fundingGoalReached && beneficiary == msg.sender) {
            if (beneficiary.send(amountRaised)) {
                FundTransfer(beneficiary, amountRaised, false);/**/
            } else {
                //If we fail to send the funds to beneficiary, unlock funders balance
                fundingGoalReached = false;
            }
        }
    }
}