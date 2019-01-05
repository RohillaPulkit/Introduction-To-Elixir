defmodule Project.MixProject do
  use Mix.Project

  def project do
    [
      app: :project1,
      escript: [main_module: Server, emu_args: "-setcookie unique"],
      version: "0.1.0",
      elixir: "~> 1.7",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      name: "Project 1"
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:ex_doc, "~> 0.19.1"},
      {:earmark, "~> 1.2.4"}
    ]
  end
end
