# BSLI NASA SSTR 3 Degrees of Freedom Simulink Model
Updated: 10/31/26

## 📖 Overview

**Welcome** to the project hub for BSLI NASA's 2026-2027 3-DOF Simulink Model! With this model you can:
- Load up your specific rocket's full configuration: geometry, thrust curve, environmental parameters, parachutes, and launch rod (The BSLI 2026 PDR Rocket is currently loaded by default!)
- Run a Simulink Model and view Signal Outputs, which can show you the evolution of the rocket's motion, aerodynamics, flight logic, and environment over time
- Vary any configuration variables you like across a sweep of different possibilities, and run permutations of these variables across thousands of runs with Monte Carlo analysis
- Use Monte Carlo outputs for lovely data visualization and better understanding of optimal rocket setups

## How to work on the model on your computer and use Git/GitHub

The default branch is **`3-DOF`**. This guide below assumes you work on it, or on a short-lived branch that gets merged back into it.

#### 1. Quick one-time setup

1. Create a GitHub account and ask the project lead to add you as a **collaborator with Write access**. Accept the email invite.
2. Install [GitHub Desktop](https://desktop.github.com) and sign in (File → Options → Accounts).
3. **File → Clone Repository**, pick this repo from the list, choose a folder **outside** OneDrive/iCloud/Dropbox (syncing breaks Git), and click **Clone**.[^1]
4. In MATLAB, open the cloned folder and open `3-DOF/model/TDOF_simulink_v2.slx`, and you'll see a model appear. The model's InitFcn finds the scripts and data on its own. You can now run the model!

#### 2. Every work session

1. Open GitHub Desktop. Check that the top bar says **Current Branch: 3-DOF**.
2. Click **Fetch origin**. If it turns into **Pull origin**, click it. Do this *before* you edit anything.[^2]
3. Do your work in MATLAB/Simulink. Save often.
4. Back in GitHub Desktop, the **Changes** tab lists what you edited. Tick only the files you meant to change.
5. Write a summary describing the change (e.g. "Add wind gust sweep to config", not "update"). Click **Commit to 3-DOF**.[^3]
6. Click **Fetch origin** again. If it says **Pull origin**, click it, then check that nothing broke.
7. Click **Push origin**.[^4]

#### 3. Rules that keep everyone out of trouble

- **Pull before you start, pull before you push.** A stale copy is the cause of nearly every Git problem.
- **Only one person edits the `.slx` model at a time.** It is a binary file, so Git cannot merge two people's edits. Message the team ("I'm editing the model") before you start, and push as soon as you finish.
- **Text files merge fine** (`.m` scripts, `config.m`, the README), so scripts and config changes can happen in parallel.
- **Commit small and often.** Many small commits are easier to undo than one huge one.
- **Never commit generated files.** `results/`, `slprj/`, `*.asv`, `*.autosave` and `*.slxc` are in `.gitignore` and shouldn't get committed. However, if one of them shows up in Changes, don't tick it.
- **Use a branch for risky or long experiments** (see below), and keep it short-lived.
- **Don't use "Force push" or "Discard" casually.** Both can delete work.

#### 4. Working on a branch (optional, for experiments)

1. **Current Branch → New Branch**, name it for the work (e.g. `drogue-sweep`), based on `3-DOF`.
2. Commit as usual, then click **Publish branch**.
3. When finished, click **Create Pull Request**. This opens GitHub, where the lead reviews and merges it into `3-DOF`.
4. After the merge, switch back to `3-DOF`, click **Pull origin**, then delete the old branch (**Branch → Delete**).[^5]

#### 5. If something goes wrong

- **Merge conflict:** GitHub Desktop lists the conflicted files. For text files, open them in MATLAB and keep the right lines. For the `.slx`, choose one whole version, and ask the other person to redo their changes on top of it.
- **Files seem to be missing:** check that you're on the right branch, then click **Pull origin**. Committed work is never lost, so look at the branch on github.com before panicking.
- **Pushed something wrong:** **History tab → right-click the commit → Revert Changes in Commit**. This adds a new commit that undoes it, without erasing history.
- **Uncommitted work blocks a branch switch:** choose **Stash** (or commit it) when GitHub Desktop asks.
- **Stuck:** don't force anything. Ask a lead, and share a screenshot or the output of `git status -sb`.

#### 6. If you'd rather use Terminal than GitHub Desktop

Equivalent Footnotes:
[^1]: Terminal equivalent: `git clone git@github.com:awinters3019/BSLI-NASA-26-27.git` (or the HTTPS URL), then `cd BSLI-NASA-26-27`. (If that failed, type `ls` and see what the main folder inside is, then switch to it). An SSH needs a key added to your GitHub account (Settings → SSH and GPG keys); HTTPS asks for a Personal Access Token as the password, not your account password.
[^2]: Terminal: `git checkout 3-DOF` then `git pull origin 3-DOF`. If Git says "need to specify how to reconcile divergent branches", run `git config pull.rebase false` once, then pull again.
[^3]: Terminal: `git status -sb` (confirm you're on `3-DOF` and see the changes), `git add <files>` (or `git add -A` for everything), `git commit -m "message"`.
[^4]: Terminal: `git pull origin 3-DOF` then `git push origin 3-DOF`.
[^5]: Terminal: `git checkout -b drogue-sweep`, then `git push -u origin drogue-sweep`. After the merge: `git checkout 3-DOF`, `git pull origin 3-DOF`, `git branch -d drogue-sweep`, `git fetch --prune`. Useful checks at any time: `git status -sb` (branch, ahead/behind), `git branch -vv` (tracking), `git log --oneline --graph --all` (history), and `git reflog` (recover "lost" commits).

# Structure

### The Simulink Model itself

A longer writeup of the how the model itself and a first version of the Monte Carlo work, which was made for PDR, can be found [here][Writeup_URL]. I strongly encourage reading this! 
However, for an overview:
- Open the model: `3-DOF/model/TDOF_simulink_v2.slx`. Hit the green "Run" button in the top bar.
- The main hub of the model is the **3-DOF block**. Signals flow into its left side (mass properties and applied forces & moments) and the rocket's resulting state flows out the right side (position, velocity, pitch, acceleration).
- These output signals (the "state") can be read by various functions to determine how we expect the rocket to have forces and moments applied to it in the next time step.
- Using starting parameters which you can place and edit in `functions/config.m`, an initializing script `NewInitFcn.m` runs, the config variables are manipulated to build an input, and the input is then sent to Simulink.
- The model compiles and everything gets ready to go. Then, every time step (less than or equal to 0.001s), data is pushed through the signal wires to the 3-DOF block and different functions throughout.
- Once the rocket lands back on the ground, the evolution of tracked signals over time is stored. You can click on the **blue Wifi signals** throughout the model and you'll see some graphs appear. Take a look at how the rocket took flight!

### MATLAB File Structure, Monte Carlo, and Custom Config

--> I will get back to you on this later. For now, play around with `config.m` and type `Monte_Carlo` in the MATLAB command window! Ask questions!


<!-- Links -->
[Writeup_URL]: https://docs.google.com/document/d/1_jLLu4PnvULfNspJSFKuOgB9FyYGekAV7Uvnbgcu5wI/edit?tab=t.0



