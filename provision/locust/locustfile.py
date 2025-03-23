from locust import HttpUser, task, between

class WebsiteUser(HttpUser):
    wait_time = between(1, 3)
    host = "http://your-app-domain.com"

    def on_start(self):
        # Perform login and store cookies if needed
        response = self.client.post("/login", {"username": "megivh@example.com", "password": "lagsl137"})
        if response.status_code != 200:
            print("Login failed!")

    @task
    def view_articles(self):
        self.client.get("/articles/")
