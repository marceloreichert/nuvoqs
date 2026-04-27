defmodule NuvoqsWeb.PageController do
  use NuvoqsWeb, :controller

  def home(conn, _params) do
    render(conn, :home)
  end
end
