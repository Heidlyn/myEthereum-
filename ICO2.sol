pragma solidity ^0.4.16;

interface token {
    function transfer(address receiver, uint amount);
}

contract Crowdsale {
    address public beneficiary;  // ļ�ʳɹ�����տ
    uint public fundingGoal;   // ļ�ʶ��
    uint public amountRaised;   // ��������
    uint public deadline;      // ļ�ʽ�ֹ��

    uint public price;    //  token ����̫���Ļ��� , token������Ǯ
    token public tokenReward;   // Ҫ����token

    mapping(address => uint256) public balanceOf;

    bool public fundingGoalReached = false;  // �ڳ��Ƿ�ﵽĿ��
    bool public crowdsaleClosed = false;   //  �ڳ��Ƿ����

    /**
    * �¼���������������Ϣ
    **/
    event GoalReached(address recipient, uint totalAmountRaised);
    event FundTransfer(address backer, uint amount, bool isContribution);
    event LogAmount(uint amount);

    /**
     * ���캯��, �����������
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
            /*һ��TOKEN��ͬ��1����̫��ETH̫���ˣ��޸Ĺ������룬��Ϊһ��TOKEN��ͬ��1��wei*/
            /*price = etherCostOfEachToken * 1 ether;*/
            price = weiCostOfEachToken * 1 wei;
            tokenReward = token(addressOfTokenUsedAsReward);   // �����ѷ����� token ��Լ�ĵ�ַ������ʵ��
    }

    /**
     * �޺�������Fallback������
     * �����Լת��ʱ����������ᱻ����
     */
    function () payable {
        require(!crowdsaleClosed);
        uint amount = msg.value;
        balanceOf[msg.sender] += amount;
        amountRaised += amount;
        LogAmount(amount);/*���3��ETH���жϴ˴���3����3*10^18*/
        /*����������������⣬���´�صıҵ�������ǳ�С���˴�*1000������ʾ
          1��ETH����1000��TOKEN/
        /*tokenReward.transfer(msg.sender, amount / price);*/
        tokenReward.transfer(msg.sender, 1000 * (amount / price));
        /*msg.sender��Ӧ���ǵ�ǰ���е��ⲿ�˺ŵĵ�ַ*/
        FundTransfer(msg.sender, amount, true);
    }

    /**
    *  ���庯���޸���modifier�����ú�Python��װ���������ƣ�
    * �����ں���ִ��ǰ���ĳ��ǰ���������ж�ͨ��֮��Ż����ִ�и÷�����
    * _ ��ʾ����ִ��֮��Ĵ���
    **/
    modifier afterDeadline() { if (now >= deadline) _; }

    /**
     * �ж��ڳ��Ƿ��������Ŀ�꣬ �������ʹ����afterDeadline�����޸���
     * �˶δ��벻����deadline���Զ����У�������Ҫ��deadlineʱ�䵽���˹����ִ��
     * �����deadlineʱ��ǰ�˹���������жϣ�Ҳ����ִ�к�������룻
     */
    function checkGoalReached() afterDeadline {
        if (amountRaised >= fundingGoal) {
            fundingGoalReached = true;
            GoalReached(beneficiary, amountRaised);
        }
        crowdsaleClosed = true;
    }


    /**
     * �������Ŀ��ʱ�����ʿ�͵��տ
     * δ�������Ŀ��ʱ��ִ���˿�
     * �˶δ��벻����deadline���Զ����У�������deadlineʱ�䵽���˹����ִ��
     * �����deadlineʱ��ǰ�˹���������жϣ�Ҳ����ִ�к�������룻
     */
    function safeWithdrawal() afterDeadline {
        /*�ڳ��ֹʱ�������ڳ�Ŀ��û�дﵽ����ִ���˿��ǰ�ⲿ�˺�*/
        /*��������δ���Ľ�׳�Բ�����Ҫʹ��Լ��ִ���߼���������Ҫ��Ҫ���ֵ�ǰ�˺�Ϊ�ڳ��ETH���˺�*/
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
        /*����ڳ�Ŀ��ﵽ�ˣ����������˺ŵ�ͬ�ڵ�ǰ�˺ţ�����ڳﵽ��ETH�����ǰ�˺�*/
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