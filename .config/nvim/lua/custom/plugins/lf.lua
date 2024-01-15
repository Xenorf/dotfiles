return {
    "ptzz/lf.vim",
    dependencies= {
        "voldikss/vim-floaterm"
    },
    init = function()
        vim.g.lf_map_keys = 0
        vim.g.lf_replace_netrw = 1
        vim.keymap.set('n', '<C-o>', ':Lf<CR>', { desc = 'Openning LF' })
    end
}
