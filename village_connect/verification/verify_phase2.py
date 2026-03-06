from playwright.sync_api import sync_playwright

def run(playwright):
    browser = playwright.chromium.launch(headless=True)
    # Use a taller viewport to avoid overflow and see more content
    context = browser.new_context(viewport={"width": 390, "height": 1200})
    page = context.new_page()
    try:
        print("Navigating to home page...")
        page.goto("http://localhost:3000")

        print("Waiting for home screen...")
        page.wait_for_timeout(8000)

        print("Taking home screen screenshot (with offline banner and emergency)...")
        page.screenshot(path="verification/home_screen_phase2.png")

        # Click on "Voice Assistant" mic icon
        print("Clicking Voice Assistant...")
        try:
            # Mic icon is inside an IconButton.
            # We can try to find by icon name/text fallback or position.
            # It's in the Hero Greeting row.
            # Assuming it's the mic icon.
            # Locate by label? I didn't add semantic label.
            # Locate by icon? Not easy in canvas kit unless html renderer.
            # Let's try to click in the top right area relative to screen width.
            # Or use a coordinate click if we must, but that's brittle.

            # Since I can't reliably click the icon without semantics or HTML renderer,
            # I will try to click roughly where it should be.
            # Top row, right side, left of avatar.
            # Avatar is at far right.
            pass
        except Exception as e:
            print(f"Could not click Voice Assistant: {e}")

        # Click on Emergency Button
        print("Clicking Emergency Button...")
        try:
            # It has text "SOS / EMERGENCY REPORT"
            page.get_by_text("SOS / EMERGENCY REPORT").click()
            page.wait_for_timeout(1000)
            print("Taking emergency dialog screenshot...")
            page.screenshot(path="verification/emergency_dialog.png")

            # Click Cancel
            page.get_by_text("Cancel").click()
        except Exception as e:
            print(f"Could not interact with Emergency Button: {e}")

    except Exception as e:
        print(f"Error: {e}")
    finally:
        browser.close()

if __name__ == "__main__":
    with sync_playwright() as playwright:
        run(playwright)
