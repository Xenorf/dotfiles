-- return {
--     "ptzz/lf.vim",
--     dependencies= {
--         "voldikss/vim-floaterm"
--     },
--     init = function()
--         vim.g.lf_map_keys = 0
--         vim.g.lf_replace_netrw = 1
--         vim.keymap.set('n', '<C-o>', ':Lf<CR>', { desc = 'Openning LF' })
--     end
-- }
return {
    "lmburns/lf.nvim",
    dependencies = {
        {
            "akinsho/toggleterm.nvim",
            version = "*",
            config = true, -- Runs require("toggleterm").setup()
        },
    },
    config = function()
        vim.g.lf_netrw = 1
        require("lf").setup({
            mappings = false,
            escape_quit = false,
            border = "none",
            winblend = 0,
            highlights = {
                NormalFloat = { guibg = "NONE" },
            }
        })
        vim.api.nvim_create_autocmd(
            "User", {
                pattern = "LfTermEnter",
                callback = function(a)
                    vim.api.nvim_buf_set_keymap(a.buf, "t", "q", "q", { nowait = true })
                end,
            })
    end,
}
