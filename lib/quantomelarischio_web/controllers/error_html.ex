defmodule QuantomelarischioWeb.ErrorHTML do
  @moduledoc """
  This module is invoked by your endpoint in case of errors on HTML requests.
  """
  use QuantomelarischioWeb, :html

  # Renders the status message for an error page, e.g. "404 Not Found".
  def render(template, _assigns) do
    Phoenix.Controller.status_message_from_template(template)
  end
end
