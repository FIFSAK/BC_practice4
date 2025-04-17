// SPDX-License-Identifier: MIT

pragma solidity ^0.8.28;

// Обновлённый интерфейс IERC20 с добавлением функции balanceOf
interface IERC20 {
    // Функция для перевода токенов с одного адреса на другой
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    // Функция для перевода токенов на указанный адрес
    function transfer(
        address recipient,
        uint256 amount
    ) external returns (bool);

    // Функция для получения баланса токенов на указанном адресе
    function balanceOf(address account) external view returns (uint256);
}

/// @title StakingContract - контракт для стейкинга токенов
/// @notice Контракт позволяет пользователям застейкать токены (например, KTA) и получать вознаграждение (например, MNA)
contract StakingContract {
    // Объявляем переменные для работы с токенами стейкинга и вознаграждения
    IERC20 public stakingToken; // Токен, который пользователи стейкают (например, KTA)
    IERC20 public rewardToken; // Токен, который выплачивается в качестве вознаграждения (например, MNA)

    // Коэффициент расчёта вознаграждения. rewardRate = 100 означает, что вознаграждение рассчитывается как (amount * 100) / 1000.
    uint256 public rewardRate = 100;

    // Сохранение количества застейканных токенов для каждого пользователя
    mapping(address => uint256) public balances;
    // Сохранение накопленных вознаграждений для каждого пользователя
    mapping(address => uint256) public rewards;

    /// @notice Конструктор контракта, принимает адреса токенов для стейкинга и вознаграждений.
    /// @param _stakingToken Адрес контракта токена для стейкинга (например, KTA)
    /// @param _rewardToken Адрес контракта токена для вознаграждений (например, MNA)
    constructor(address _stakingToken, address _rewardToken) {
        stakingToken = IERC20(_stakingToken);
        rewardToken = IERC20(_rewardToken);
    }

    /// @notice Функция для стейкинга токенов.
    /// @dev Пользователь должен сначала вызвать approve() на контракте stakingToken, чтобы разрешить StakingContract переводить токены.
    /// @param amount Количество токенов для стейкинга (в минимальных единицах, например, wei)
    function stake(uint256 amount) public {
        require(amount > 0, "You can't stake 0 tokens");

        // Переводим токены от пользователя на адрес контракта.
        // Если перевод не проходит, транзакция прерывается.
        bool success = stakingToken.transferFrom(
            msg.sender,
            address(this),
            amount
        );
        require(success, "Token transfer failed");

        // Обновляем баланс застейканных токенов для пользователя.
        balances[msg.sender] += amount;
        // Расчитываем вознаграждение и добавляем его к накопленным вознаграждениям.
        // Формула: (amount * rewardRate) / 1000
        rewards[msg.sender] += (amount * rewardRate) / 1000;
    }

    /// @notice Функция для получения вознаграждений.
    /// @dev Вознаграждения переводятся из баланса rewardToken, который должен быть пополнен заранее.
    function claimRewards() public {
        require(rewards[msg.sender] > 0, "No available rewards");

        uint256 reward = rewards[msg.sender];
        // Обнуляем накопленные вознаграждения до перевода
        rewards[msg.sender] = 0;

        // Переводим вознаграждение пользователю. Если перевод не проходит, транзакция прерывается.
        require(
            rewardToken.transfer(msg.sender, reward),
            "Reward transfer failed"
        );
    }

    /// @notice Функция для получения балансов токенов, находящихся на балансе контракта.
    /// @dev Позволяет узнать, сколько токенов стейкинга (KTA) и вознаграждений (MNA) хранится на контракте.
    /// @return stakingBalance Баланс токенов для стейкинга (KTA) на контракте.
    /// @return rewardBalance Баланс токенов для вознаграждений (MNA) на контракте.
    function getContractBalances()
    public
    view
    returns (uint256 stakingBalance, uint256 rewardBalance)
    {
        stakingBalance = stakingToken.balanceOf(address(this));
        rewardBalance = rewardToken.balanceOf(address(this));
    }
}
