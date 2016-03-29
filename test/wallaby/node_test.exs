defmodule Wallaby.NodeTest do
  use Wallaby.ServerCase, async: true
  use Wallaby.DSL

  setup do
    {:ok, session} = Wallaby.start_session

    on_exit fn ->
      Wallaby.end_session(session)
    end

    {:ok, %{session: session}}
  end

  test "can find an element on a page", %{server: server, session: session} do
    element =
      session
      |> visit(server.base_url)
      |> find("#header")

    assert element
  end

  test "finding nonexistent elements raises an exception", %{server: server, session: session} do
    assert_raise Wallaby.ElementNotFound, fn ->
      session
      |> visit(server.base_url)
      |> find("#not-there")
    end
  end

  test "ambiguous queries raise an exception", %{server: server, session: session} do
    assert_raise Wallaby.AmbiguousMatch, fn ->
      session
      |> visit(server.base_url)
      |> find("a")
    end
  end

  test "can query for multiple elements", %{server: server, session: session} do
    elements =
      session
      |> visit(server.base_url)
      |> all("a")

    assert length(elements) == 3
  end

  test "queries can be scoped to nodes", %{server: server, session: session} do
    users =
      session
      |> visit(server.base_url <> "nesting.html")
      |> find(".dashboard")
      |> find(".users")
      |> all(".user")

    assert Enum.count(users) == 3
    assert List.first(users) |> text == "Chris"
  end

  test "empty list is returned when all does not match", %{server: server, session: session} do
    elements =
      session
      |> visit(server.base_url)
      |> all("table")

    assert elements == []
  end

  test "can get text of an element", %{server: server, session: session} do
    text =
      session
      |> visit(server.base_url)
      |> find("#header")
      |> text

    assert text == "Test Index"
  end

  test "has_content?/2 asserts text in an element", %{server: server, session: session} do
    node =
      session
      |> visit(server.base_url)
      |> find("#header")

    assert has_content?(node, "Test Index")
  end

  test "can get attributes of an element", %{server: server, session: session} do
    class =
      session
      |> visit(server.base_url)
      |> find("body")
      |> attr("class")

    assert class == "bootstrap"
  end

  test "filling in input by name", %{server: server, session: session} do
    session
    |> visit(server.base_url <> "forms.html")
    |> fill_in("name", with: "Chris")

    assert find(session, "#name_field") |> has_value?("Chris")
  end

  test "filling in input by id", %{server: server, session: session} do
    session
    |> visit(server.base_url <> "forms.html")
    |> fill_in("name_field", with: "Chris")

    assert find(session, "#name_field") |> has_value?("Chris")
  end

  test "filling in multple inputs", %{server: server, session: session} do
    session
    |> visit(server.base_url <> "forms.html")
    |> fill_in("name", with: "Alex")
    |> fill_in("email", with: "alex@example.com")

    assert find(session, "#name_field")  |> has_value?("Alex")
    assert find(session, "#email_field") |> has_value?("alex@example.com")
  end

  test "clearing input", %{server: server, session: session} do
    node =
      session
      |> visit(server.base_url <> "forms.html")
      |> find("#name_field")

    fill_in(node, with: "Chris")
    assert has_value?(node, "Chris")

    clear(node)
    refute has_value?(node, "Chris")
    assert has_value?(node, "")
  end

  test "choosing a radio button", %{session: session, server: server} do
    page =
      session
      |> visit(server.base_url <> "forms.html")

    refute find(page, "#option2") |> checked?

    page
    |> choose("option2")

    assert find(session, "#option2") |> checked?
  end

  test "choosing a radio button unchecks other buttons in the group", %{session: session, server: server} do
    session
    |> visit(server.base_url <> "forms.html")

    choose(session, "Option 1")
    assert find(session, "#option1") |> checked?

    find(session, "#option2")
    |> choose()

    refute find(session, "#option1") |> checked?
    assert find(session, "#option2") |> checked?
  end

  test "check/1 checks the specified node", %{session: session, server: server} do
    checkbox =
      session
      |> visit(server.base_url <> "forms.html")
      |> find("#checkbox1")

    check checkbox
    assert checked?(checkbox)
    uncheck checkbox
    refute checked?(checkbox)
  end

  test "check/2 does not uncheck the node if called twice", %{session: session, server: server} do
    session
    |> visit(server.base_url <> "forms.html")
    |> check("Checkbox 1")
    |> check("Checkbox 1")

    assert find(session, "#checkbox1") |> checked?
  end

  test "uncheck/2 does not check the node", %{session: session, server: server} do
    session
    |> visit(server.base_url <> "forms.html")
    |> uncheck("Checkbox 1")

    refute find(session, "#checkbox1") |> checked?
  end

  test "check/2 finds the node by label", %{session: session, server: server} do
    session
    |> visit(server.base_url <> "forms.html")
    |> check("Checkbox 1")

    assert find(session, "#checkbox1") |> checked?
    uncheck(session, "Checkbox 1")
    refute find(session, "#checkbox1") |> checked?
  end

  test "check/2 finds the node by id", %{session: session, server: server} do
    session
    |> visit(server.base_url <> "forms.html")
    |> check("checkbox1")

    assert find(session, "#checkbox1") |> checked?
    uncheck(session, "checkbox1")
    refute find(session, "#checkbox1") |> checked?
  end

  test "check/2 finds the node by name", %{session: session, server: server} do
    session
    |> visit(server.base_url <> "forms.html")
    |> check("testbox")

    assert find(session, "#checkbox1") |> checked?
    uncheck(session, "testbox")
    refute find(session, "#checkbox1") |> checked?
  end

  test "waits for an element to be visible", %{session: session, server: server} do
    session
    |> visit(server.base_url <> "wait.html")

    assert all(session, ".main") == []

    assert find(session, ".main")
  end

  test "waits for count elements to be visible", %{session: session, server: server} do
    session
    |> visit(server.base_url <> "wait.html")

    assert all(session, ".orange") == []

    assert find(session, ".orange", count: 5) |> length == 5
  end

  test "finding one or more elements", %{session: session, server: server} do
    session
    |> visit(server.base_url <> "page_1.html")

    assert_raise Wallaby.ElementNotFound, fn ->
      find(session, ".not-there", count: :any)
    end

    assert find(session, "li", count: :any) |> length == 4
  end

  test "executing scripts with arguments and returning", %{session: session, server: server} do
    script = """
      var node = document.createElement("div")
      node.id = "new-element"
      var text = document.createTextNode(arguments[0])
      node.appendChild(text)
      document.body.appendChild(node)
      return arguments[1]
    """

    result =
      session
      |> visit(server.base_url <> "page_1.html")
      |> execute_script(script, ["now you see me", "return value"])

    assert result == "return value"
    assert find(session, "#new-element") |> text == "now you see me"
  end

  test "sending text", %{session: session, server: server} do
    session
    |> visit(server.base_url <> "forms.html")

    session
    |> find("#name_field")
    |> click

    session
    |> send_text("hello")

    assert session |> find("#name_field") |> has_value?("hello")
  end

  test "sending key presses", %{session: session, server: server} do
    session
    |> visit(server.base_url)

    session
    |> send_keys([:tab, :enter])

    assert find(session, ".blue")
  end
end
