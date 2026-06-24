# FinancePilot

FinancePilot is an offline-first personal financial GPS and digital advisor built with **Flutter**, **Riverpod**, and **Hive**.

Most personal finance applications only report historical bookkeeping (e.g., "You spent $200 on food this month"). FinancePilot operates as an active financial navigator. By combining transaction records, outstanding debts, saving targets, and income stability factors, it guides users on their **Next Best Move**, calculates a **Financial Health Score**, feeds proactive coaching recommendations, and models future scenarios in a **24-Month What-If Simulator**.

---

## 🌟 Core Features

### Level 1: Expense & Income Tracking

* Track incomes, expenses, and recurring transactions.
* Custom categories (Food, Rent, Salary, Freelance, Equb, utilities, etc.).
* Track payment methods: **Cash**, **Telebirr**, **CBE Birr**, and **Bank**.

### Level 2: Financial Health Score (Out of 100)

A dynamic, real-time score built from five weighted sub-metrics:

* **Savings Rate (25% weight)**: Targets a savings rate $\ge 25\%$ of net income.
* **Emergency Fund (25% weight)**: Evaluates reserves against basic monthly expenses (target is 3 months for salaried workers, 6 months for daily earners).
* **Debt-to-Income Ratio (20% weight)**: Measures debt obligations against monthly income (target is $< 10\%$, ratios $> 40\%$ reduce this sub-score to 0).
* **Investment Rate (15% weight)**: Encourages allocating $\ge 15\%$ of income to long-term wealth building.
* **Income Stability (15% weight)**: Adjusts risk thresholds based on employment type, buffering daily earners with higher reserve requirements.

### Level 3: Rules-Based AI Coach

* Local rule engine translates financial ratios into clear, actionable natural language recommendations.
* Categorizes alerts by priority (e.g., Warning, Focus, Tip) to guide daily cash decisions.
* Includes an educational panel explaining the benchmarks behind standard personal finance guidelines (Savings rates, DTI safety, and Emergency buffers).

### Level 4: Goal Planning

* Set targets: **Emergency Fund**, **House**, **Car**, **Wedding**, **Vacation**, **Business Capital**, and **Retirement**.
* Calculates required monthly savings rates based on custom deadlines.
* Shows active progress tracking with color-coded visual rings.

### Level 5: Priority Financial GPS Roadmap

An automated priority queue guiding users through sequential milestones:

1. **Starter Emergency Fund**: 1 month of basic expenses as a defensive shield.
2. **Toxic Debt Payoff**: Concentrating surplus income to clear outstanding loans (e.g., CBE loans, personal debts).
3. **Full Emergency Fund**: Accumulating the complete 3-to-6 month reserve.
4. **Life Goals & Wealth Building**: Directing cash surpluses into parallel saving targets and investments.

* Tracks milestones dynamically as Completed, Active (with progress bar), or Locked.

### Level 6: 24-Month What-If Simulator

An interactive compound forecasting canvas:

* Drag sliders to model **Saving Extra Cash** or **Salary Increases**.
* Enter parameters to simulate a **Major Asset Purchase** (e.g., buying a car in Month 4 with a designated down payment and recurring maintenance costs).
* Renders a double-line timeline graph (`fl_chart`) plotting projected savings reserves vs outstanding debt over 24 months.
* Analyzes and prints the exact impact of decisions on other active goals (e.g., *"Buying this car delays your House goal by 4 months"*).

### Level 7: Ethiopian-Friendly Differentiators

* **Multi-Wallet Balance Board**: Estimates balances for **Telebirr**, **CBE Birr**, **Cash**, and **Bank** based on transaction histories, making wallet reconciliation simple.
* **Traditional Equb Planner**:
  * Set up Equb savings groups: contribution amount, cycle frequency (weekly/monthly), total members, contribution day, and your payout slot.
  * Pay contributions interactively: the app logs the expense and increments the round.
  * When your payout round is reached, it triggers a winner celebration dialog, automatically logs the lump-sum pot as an income source, and adjusts your cash balance.

---

## 🛠️ Tech Stack & Architecture

FinancePilot is built with a feature-first, clean architecture:

* **Framework**: Flutter (Material 3 Dark Theme)
* **State Management**: Riverpod (Notifier-based state management, combined reactive providers)
* **Database**: Hive & Hive Flutter (Lightweight, local-first NoSQL database using JSON serialization)
* **Visualization**: FL Chart (Responsive line and radial progress graphs)
* **Fonts**: Google Fonts (`Plus Jakarta Sans`)

### Directory Structure

```text
lib/
├── core/
│   ├── theme/          # Slate-navy dark theme & styling tokens
│   └── storage/        # Hive database box initialization & storage helpers
├── models/             # Data models with JSON serialization
│   ├── transaction.dart
│   ├── goal.dart
│   ├── debt.dart
│   ├── equb.dart
│   └── profile.dart
├── services/           # Calculations and business logic
│   ├── finance_rules.dart # Local Rule Engine (Health score & advisor)
│   └── simulator.dart     # 24-Month What-If forecasting projections
├── providers/          # Riverpod state managers and listeners
│   ├── financial_provider.dart
│   └── simulator_provider.dart
└── views/              # Responsive Material 3 layouts
    ├── main_shell.dart       # Bottom nav / desktop NavigationRail & log dialog
    ├── dashboard_view.dart   # Health gauge dial, findings, profile editor
    ├── transactions_view.dart # Wallet cards & filtered transaction logs
    ├── roadmap_view.dart     # GPS priority step timeline
    ├── coach_view.dart       # Advice feed & financial educational panel
    ├── goals_view.dart       # Target goals & traditional Equb trackers
    └── simulator_view.dart   # Interactivesliders & 24-month line graph
```

---

## 🚀 Getting Started

### Prerequisites

* Flutter SDK (Dart 3.9.0 / Flutter 3.35.2 or later)

### Installation & Run

1. Clone the repository and navigate to the project directory:

   ```bash
   cd FinancePilot
   ```

2. Fetch the dependencies:

   ```bash
   flutter pub get
   ```

3. Run the application in Chrome (Web is the recommended target on Windows due to symlink requirements for desktop plugins):

   ```bash
   flutter run -d chrome
   ```

---

## 🧪 Verification & Testing

The repository contains a unit test suite verifying the mathematical calculations of the rule engine and the forecast simulator.

To run the unit tests:

```bash
flutter test
```

All five unit tests cover:

* Required monthly saving rates.
* Progress percentages.
* Salaried vs Daily Earner health score calculations (DTI, Savings rate, Emergency fund coverage).
* 24-month compound savings growth and debt payoff forecasting.
