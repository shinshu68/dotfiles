local opt = vim.opt

opt.termguicolors = true
vim.cmd.colorscheme("habamax")

opt.expandtab = true
opt.tabstop = 4
opt.softtabstop = 4
opt.shiftwidth = 4
opt.shiftround = true

opt.number = true
opt.showbreak = "↪"
opt.list = true
opt.listchars = { tab = "⊳-", trail = "‗" }
opt.scrolloff = 5

opt.matchpairs:append("<:>")
opt.showmatch = true
opt.matchtime = 3

opt.ignorecase = true
opt.smartcase = true
opt.infercase = true

opt.swapfile = false

vim.g.mapleader = " "

local map = vim.keymap.set

map("i", "jj", "<Esc>", { silent = true })
map("i", "ｊｊ", "<Esc>", { silent = true })
map("t", "jj", "<C-\\><C-n>", { silent = true })

map("n", "<Esc><Esc>", "<Cmd>set hlsearch!<CR>", { silent = true })
map("n", "<Leader>w", "<Cmd>write<CR>")
map("n", "<Leader>h", "^")
map("n", "<Leader>l", "$")
map("n", "<Leader>/", "*")
map("n", "<Leader>m", "%")
map("n", "<Leader><Tab>", "<C-w>w")

map("c", "<C-v>", "<C-r>0")
