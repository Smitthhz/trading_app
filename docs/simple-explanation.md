# The Simple Guide — What We Built and How It Works

No jargon walls, no assumption that you already know Flutter. This is written the way you'd explain it to a friend over coffee. If you read this once, you should be able to talk through the whole app confidently — what it does, how the pieces fit, and why we made the choices we made.

There's a more technical companion doc (`concepts-and-architecture.md`) if you ever want the precise, code-level version of anything below. Think of this file as the story, and that one as the manual.

---

## 1. What is this app, in one breath?

It's a pretend stock trading app. You get a fake ₹1,00,000 to start with. Ten stock prices wiggle up and down on their own, all the time, like a little simulation running in the background. You can watch stocks you like, buy and sell them, see how much money you're making or losing, and look back at everything you've traded. Nothing is real — there's no real market, no real money, no internet connection needed. It all happens on your device.

---

## 2. Why is the code organized into folders the way it is?

Imagine your bedroom. You could throw everything in one big pile — clothes, books, chargers, all mixed together. It "works," technically, you can still find things eventually. Or you could have a wardrobe for clothes, a shelf for books, a drawer for cables. Takes a bit more effort to set up, but later, when you want a specific pair of socks, you know exactly where to look.

That's what we did with the code. Everything about "orders" (buying and selling) lives together in one folder. Everything about "watchlists" lives together in another. Inside each of those folders, we split things three ways:

- **The rules** (called "domain") — the actual business logic. Like: "you can't sell more shares than you own." This part doesn't know or care that it's inside a phone app — it's just plain logic, the kind you could test on paper.
- **The plumbing** (called "data") — the part that actually goes and gets or stores information. Right now that's a pretend price generator and a bit of on-device storage.
- **The screen** (called "presentation") — the actual buttons, text, and colors you see and tap.

**Why bother splitting it up like this?** Because the "rules" part never needs to know *how* prices arrive or *where* things get saved. If tomorrow we wanted to connect this app to a real stock exchange instead of a pretend one, we'd only need to swap out the "plumbing" — the rules and the screens wouldn't need to change at all. It also means we can test "can't sell more than you own" with a tiny, fast test, without ever needing to open the actual app.

Is this the *only* way to organize a Flutter app? No. For a much smaller app — say, a single-screen calculator — this would be way more structure than you need, like alphabetizing a spice rack with three spices in it. We used it here because the app has several real features that all need to talk to shared things (the same wallet, the same live prices), and that's exactly when this kind of organization starts paying for itself.

---

## 3. How does a screen "know" when something changes?

Here's the core idea, and everything else in the app builds on it.

Every feature (Market, Watchlists, Orders, Holdings) has something we call a **Cubit** — think of it as a personal assistant assigned to that feature. The screen never touches the data directly. Instead, the screen says to its assistant, "hey, please buy 5 shares of Reliance," and the assistant does the actual work, then says, "done, here's the new situation," and the screen redraws itself to match.

Why not let the screen just do everything itself? Two reasons:
1. **One clear place for the logic.** If ten different buttons across the app all needed to know "how do I safely deduct money from the wallet," you'd end up copying that logic ten times, and if you found a bug in it, you'd have to fix it in ten places.
2. **The screen can be "dumb."** It just says what it wants and draws whatever it's told. That makes it much easier to test and much easier to reason about — you don't have to worry about a button secretly changing three different things behind your back.

For most features, the assistant is simple: you ask it to do one thing, it does it, done. But buying/selling has a few real *steps* — you're filling in the form, then it's submitting, then it either succeeded or failed. For that one flow, we used a slightly stricter version of the same idea (called a **Bloc**) that forces you to go through the steps in order — you can't accidentally skip straight to "it succeeded" without actually submitting first.

---

## 4. How do the live prices actually move?

Picture a radio station that, once a second, announces the new price of all ten stocks over the air. That's the mock price feed — it's just a timer that goes off regularly and makes up a small random price move for each stock.

Every row on screen is like someone with a radio tuned to *only their station*. The AXISBANK row only cares about AXISBANK's announcements — when TCS's price changes, AXISBANK's row doesn't even twitch. That matters a lot, because with 10 stocks all changing multiple times a second, if every single row redrew itself every time *any* stock changed, the screen would visibly stutter. Instead, only the one row that actually has new information redraws — the other nine just sit there, untouched.

The radio station itself never turns off, even if you're not looking at the Market screen. It's started once when the app launches and just keeps going in the background, which is why prices are still "current" if you switch to Watchlists and come back to Market later.

We also added a little **pause button** for this — tap it, and the radio station goes quiet (prices freeze exactly where they were). Tap it again, and it starts broadcasting again from wherever prices are now.

---

## 5. Why does money get stored as a whole number instead of a normal decimal?

Here's a fun, slightly annoying fact about computers: they're bad at exact decimals. If you ask a computer to add 0.1 and 0.2 using the "normal" way of storing decimal numbers, you sometimes get something like `0.30000000000000004` instead of a clean `0.3`. For most things that tiny error doesn't matter. For money, it can — do that kind of math thousands of times across a lot of trades, and the errors can pile up into something visibly wrong.

The fix is almost embarrassingly simple: **never store money as a decimal at all.** Instead of storing "₹123.45," we store "12345 paise" — a plain whole number, the same way you'd count out coins instead of measuring with a ruler that's slightly off. Whole numbers add and subtract *exactly*, every single time, no surprises. We only turn it back into "₹123.45" for display, right at the very last moment, when it's actually shown on screen.

---

## 6. What actually happens when you tap "Buy"?

Say you tap on Reliance, type in a quantity, and hit "Place Buy Order." Here's the important detail: the moment you hit submit, the app takes a single, one-time "photo" of Reliance's current price and uses *that exact number* for everything — checking if you can afford it, deducting your wallet, recording the trade, and showing you the confirmation screen.

Why does that matter? Because prices are changing constantly in the background. If the app instead checked the price fresh at each of those steps (once to validate, again to charge you, again to show the receipt), and the price happened to tick in between those checks, you could end up being charged a different price than the one you saw when you clicked "Buy." That would feel broken and unfair — like a shop showing you a price tag, then charging you something else at the register. Taking one snapshot and using it everywhere guarantees what you saw is what you got.

---

## 7. How does the app remember things after you close it?

Everything you care about — your wallet balance, your watchlists, what you're holding, your order history — gets bundled up into one tidy little package and saved on your device, kind of like writing everything down in a single notebook page before you go to sleep, instead of scribbling separate notes on ten different sticky notes.

Why one page instead of ten sticky notes? Two reasons. First, it's simpler — there's one thing to save and one thing to load. Second, and more importantly, it avoids a nasty possible bug: imagine if saving your wallet and saving your holdings were two *separate* steps, and the app happened to close (crash, phone dies, whatever) right in between those two steps. You could end up with a wallet that says you spent money, but holdings that don't show you bought anything — an inconsistent, confusing mess. Saving everything together as one bundle means it's always all-or-nothing: either the whole updated picture gets saved, or none of it does.

If that saved notebook page is ever missing or somehow corrupted (first launch, or something went wrong), the app doesn't crash — it just quietly starts you fresh with an empty watchlist and your starting ₹1,00,000, the same as a brand new install.

---

## 8. Dark mode — how does the app "change outfits"?

Think of the app as owning two outfits — a light one and a dark one — both cut from the same "fabric pattern" so they always look coordinated, never mismatched. We pick one base color (a blue), and Flutter's tools automatically work out a whole matching set of shades for buttons, backgrounds, cards, and so on — for *both* outfits — so we never had to hand-pick twenty different colors ourselves and hope they looked good together.

There's one extra wrinkle: this app also uses green for "you're up" and red for "you're down," and those aren't part of the automatic outfit — they're specific to what this particular app needed. So we defined our own little "extra pocket" for those two colors, one version for the light outfit and one for the dark outfit, so a red "you're down" badge still looks crisp and readable no matter which outfit is on. (Early on, we actually had these colors hardcoded directly onto ~15 different bits of the screen — which is exactly the kind of thing that looks fine in the light outfit and washes out badly in the dark one. Centralizing it into one place fixed that everywhere at once.)

The little toggle button in the corner just cycles through three settings: "match my phone's setting," "always light," "always dark" — and remembers your choice for next time you open the app.

---

## 9. What are those tiny squiggly lines next to each price?

Those are called sparklines — miniature line charts, no numbers or axis labels, just a quick visual "has this been trending up or down lately?" We draw them ourselves with basic drawing instructions (imagine holding a pen and just connecting a series of recent price dots with straight lines) rather than using a big, full-featured charting toolkit. A full charting tool is built for things like zooming in, tapping points to see exact values, multiple chart types — none of which this tiny inline squiggle needs. Using the lightweight, homemade version keeps the app smaller and simpler, and it was genuinely easy to build once you know the trick (draw a line connecting some points, that's basically it).

---

## 10. Search and sort on the Market screen

Typing into the search box, or tapping "Price"/"% Change" to reorder the list — that's all handled right there on the screen itself, without needing to ask any "assistant" (Cubit) for help. Why? Because that information (what you typed, which sort you picked) only matters *while you're looking at that screen*. The moment you navigate away, there's no reason for the app to remember it — it's not like your wallet balance, which matters everywhere. Using the simplest tool that does the job, instead of routing everything through the same "assistant" pattern out of habit, keeps things easy to follow.

---

## 11. The new "Activity" tab

This is simply a list of every trade you've ever made in the app, most recent first — like a bank statement, but for your pretend trades. It didn't need any new "brain" of its own; it just reads the same order history that was already being saved for the confirmation screens, and displays it as a scrollable list.

---

## 12. Some real bugs we found — and what they teach us

It's worth walking through these, because they're the kind of mistake that's easy to make and genuinely useful to recognize next time.

**The "stuck after a failed trade" bug.** If you tried to buy more shares than you could afford, the app correctly told you "insufficient balance" — but then the whole ticket screen just... stopped responding. You couldn't change the quantity, couldn't try again, nothing. The only way out was to leave and start over. Why did this happen? The app's internal "assistant" for the order screen only knew how to react to your typing *while things were going smoothly*; the moment something failed, it fell into a state it simply hadn't been taught to recover from. The fix: teach it that if you start typing again after a failure, it should snap back into "normal editing" mode instead of staying frozen.

**The "error message that wouldn't go away" bug.** Closely related: if you got a validation error (like typing "0" as your quantity), and then fixed it by typing a proper number, the error message — and the disabled button — sometimes stayed stuck, even though your new input was perfectly valid. The app just wasn't clearing the *old* complaint when new, valid information came in. Simple fix, easy to miss.

**The "right animation, wrong stock" risk.** Once we added the ability to reorder the stock list (by sorting or searching), we realized the screen had no reliable way to tell "this row is AXISBANK" apart from "this is just whatever happens to be in position #3 right now." Normally that's invisible, but if two stocks swapped positions in the list, the little flash animation that's supposed to belong to one stock could end up firing on a completely different one that happened to slide into the same slot. The fix was giving every row a proper, permanent name tag (its stock symbol) so the screen always knows exactly which row is which, no matter how the list gets reordered.

**The "app not ready yet" race.** Right when the app first opens, there's a tiny sliver of time where it's still loading your saved wallet and holdings from storage. If you were fast enough to tap a stock and try to trade in that exact sliver, the app could crash, because it assumed that information would always already be there. We added a proper check — "if we're not ready yet, just show a friendly message and don't let you in" — so instead of crashing, worst case you just see "not ready yet, try again" for a fraction of a second.

None of these were exotic bugs. They were all "the code assumed something would always be true, and there was a small window where it wasn't." That's most real-world bugs, honestly — and it's exactly why we write tests that click through real user flows, not just tests that check a formula gives the right number.

---

## 13. Why do we bother testing, and what does that even mean here?

There are two flavors of test in this project. **Unit tests** are small and fast — they check that one specific bit of logic behaves correctly, like "if I buy shares I can't afford, does the app correctly say no?" **Widget tests** are heavier — they actually simulate a person tapping through the real app: opening a ticket, typing a quantity, hitting submit, checking the right thing shows up on the confirmation screen.

The widget tests are the ones that actually *found* several of the bugs above — because they behave like a real, slightly impatient user (tapping something the instant it appears, before the app's had a chance to fully settle), they stumble into exactly the timing gaps a human eventually would too.

---

## 14. If someone asks you about this project, here's your cheat sheet

- **"What's it built with?"** → Flutter, using a pattern called BLoC/Cubit for managing what's on screen, and simple on-device storage for saving your data.
- **"Why not just put everything in one big file?"** → Because features would get tangled together, and it'd be much harder to test the actual business rules (like "can't sell more than you own") without needing the whole app running.
- **"How do live prices update without the app hanging?"** → Only the specific row whose price actually changed gets redrawn — the other nine sit still, so nothing has to redo more work than it needs to.
- **"Why whole numbers for money?"** → Because computers can introduce tiny rounding errors with decimals, and you never want that anywhere near real (or pretend) money.
- **"What happens the instant I hit Buy?"** → The app locks in the price at that exact moment and uses that same number for everything from validation to your receipt, so what you saw is exactly what you get.
- **"Does it remember my trades if I close the app?"** → Yes — everything gets saved together as one bundle, so it's never in a half-saved, inconsistent state.
- **"How does dark mode work?"** → One base color generates a whole matching light and dark palette automatically, plus a couple of app-specific colors (profit green / loss red) that we made sure adjust properly for both.
- **"What are the little charts next to prices?"** → Hand-drawn mini trend lines — deliberately simple, not a big charting library, because they don't need to do anything fancy.
- **"What bugs did you find and fix?"** → A frozen order screen after a failed trade, a stuck error message, a risk of animations attaching to the wrong stock after sorting, and a rare startup-timing crash — all found by testing real user flows, not just formulas.
