# Submission walkthrough script

Target length: 2–3 minutes. Record on an Android device, iOS simulator, macOS, or Chrome with the app already running.

## 1. Open with the market overview — 20 seconds

1. Launch the app on the **Market** tab.
2. Point out the ten fixed NSE symbols, changing LTP/change values, the green/red update flash, and the sparkline.
3. Enter a symbol in Search, clear it, then change the sort option.
4. Pause and resume the feed to show that the debug control works.

Suggested narration: “This is a single mock market-data feed shared by every screen. Each row listens only to its own symbol, so updates remain smooth even at the configured stress rate.”

## 2. Manage a watchlist — 40 seconds

1. Open **Watchlists** and show the first-launch empty state.
2. Create a watchlist named “Demo”.
3. Use the stock picker to add RELIANCE and TCS.
4. Attempt to add RELIANCE again and show the duplicate prevention.
5. Drag TCS to reorder it, then remove it using the row action.
6. Tap RELIANCE to open its pre-filled order ticket.

Suggested narration: “Watchlists support multiple named lists, persistent ordering, removal, and duplicate prevention. The same live quote is rendered consistently anywhere a stock appears.”

## 3. Place a simulated order — 45 seconds

1. In the order ticket, show the live LTP and projected order value.
2. Enter zero or a fractional quantity to demonstrate inline validation.
3. Enter an amount above the available balance to show the insufficient-balance error.
4. Enter a valid buy quantity, submit, and show the confirmation with its snapshotted execution price.
5. Return to the ticket, switch to **Sell**, and enter more shares than held to show the quantity-held validation.

Suggested narration: “The price is snapshotted once at submission. All money uses integer paise, so the wallet, order value, and average cost avoid floating-point drift.”

## 4. Show live holdings and persistence — 35 seconds

1. Open **Holdings** and show the new RELIANCE position, average cost, current value, live P&L, and aggregate summary.
2. Change the sort mode to P&L, symbol, and current value.
3. Sell the remaining position and show that the holding disappears at zero quantity.
4. Open **Activity** to show the persisted order history.
5. Restart the app (or close/reopen it) and show that the watchlist, wallet, holdings, and activity history remain.

Suggested narration: “Portfolio totals are derived from the same central calculation layer as each row. Persisted state restores safely across restarts, while the market feed immediately resumes with current live quotes.”

## Recording checklist

- Keep device notifications off and remove any unrelated windows.
- Use a fresh launch for the empty-state sequence, then complete the order/holdings flow in one take.
- Confirm text and values are readable at normal playback size.
- Name the final file `trading-app-walkthrough.mp4` and upload it with the assignment submission (or host it in Loom and add the share link to the submission form).
