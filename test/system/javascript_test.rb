require "application_system_test_case"

class JavascriptTest < ApplicationSystemTestCase
  test "Stimulus connects and Turbo navigates between pages" do
    visit root_path
    assert_selector "h1", text: "Calendar"

    page.execute_script <<~JS
      const element = document.createElement("div")
      element.setAttribute("data-controller", "hello")
      document.body.appendChild(element)
      window.addEventListener("turbo:load", () => sessionStorage.setItem("turbo-loaded", "yes"))
    JS
    assert_selector "[data-controller='hello']", text: "Hello World!"

    click_link "Админка"
    assert_selector "h1", text: "Админка скоро появится"
    assert_equal "yes", page.evaluate_script("sessionStorage.getItem('turbo-loaded')")
  end
end
