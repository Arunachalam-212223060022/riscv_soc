#!/bin/bash
# ============================================================
# Push this repo to: https://github.com/Arunachalam-212223060022/riscv_soc
# Run this from inside the repo folder ONCE after cloning/extracting
# ============================================================

echo "Adding remote origin..."
git remote add origin https://github.com/Arunachalam-212223060022/riscv_soc.git

echo "Renaming branch to main..."
git branch -m master main

echo "Pushing to GitHub..."
echo "(You will be prompted for your GitHub username and Personal Access Token)"
git push -u origin main

echo ""
echo "Done! Visit: https://github.com/Arunachalam-212223060022/riscv_soc"
