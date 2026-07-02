defmodule QuantomelarischioWeb.Gettext do
  @moduledoc """
  A module providing Internationalization with a gettext-based API.

  By using [Gettext](https://hexdocs.pm/gettext), your module gains a set of
  macros for translations, for example:

      use Gettext, backend: QuantomelarischioWeb.Gettext

      # Simple translation
      gettext("Here is the string to translate")

      # Plural translation
      ngettext("Here is the string to translate",
               "Here are the strings to translate",
               3)
  """
  use Gettext.Backend, otp_app: :quantomelarischio
end
