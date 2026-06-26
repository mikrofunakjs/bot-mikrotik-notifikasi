# =============================================================================
#  bot-send — fungsi global untuk kirim pesan ke Telegram
# =============================================================================
#  Cara pakai:
#   Winbox → System → Scripts → Add (+)
#     Name: bot-send
#     Policy: read, write, policy, test
#   Copy-paste isi di bawah ke kolom Source, OK.
# =============================================================================

:global botToken
:global botChatId
:global botSend do={
    :global botToken
    :global botChatId
    :local msg $0
    :local url "https://api.telegram.org/bot$botToken/sendMessage"
    :local data "chat_id=$botChatId&text=$msg&parse_mode=HTML"
    :do {
        /tool fetch url="$url" http-method=post http-data="$data" mode=https keep-result=no
    } on-error={
        :log warning "bot-send: Gagal kirim ke Telegram"
    }
}
