from locust import HttpUser, task, between

class WebsiteUser(HttpUser):
    wait_time = between(1, 3)  # Simulates think time between requests

    @task(2)
    def view_homepage(self):
        self.client.get("/")

    @task(1)
    def view_article(self):
        self.client.get("/articles/1")  # Replace with a valid slug/id
