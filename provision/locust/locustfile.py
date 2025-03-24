from locust import HttpUser, task, between
import os

class WebsiteUser(HttpUser):
    wait_time = between(1, 3)
    host = os.getenv("LOCUST_TARGET_HOST")

    def on_start(self):
        # Perform login and store cookies if needed
        response = self.client.post("/", {"username": "megivh@example.com", "password": "lagsl137"})
        if response.status_code != 200:
            print("Login failed!")

    @task(3)
    def view_articles(self):
        self.client.get("/articles/")
        self.client.get("/")
    
    @task(1)
    def create_articles(self):
        self.client.get("/create_article/")

