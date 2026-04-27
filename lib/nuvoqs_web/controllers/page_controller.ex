defmodule nuvoQsWeb.PageController do
  use nuvoQsWeb, :controller

  def home(conn, _params) do
    render(conn, :home)
  end
end
