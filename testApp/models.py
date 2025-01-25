import re
from django.db import models
from django.conf import settings
from django.contrib.auth.models import AbstractUser
from django.utils.translation import gettext_lazy as _

# file related to the database model and what will be saved in the backend.

ARTICLE_STATUS = (
        ("draft", "draft"),
        ("in progress", "in progress"),
        ("published", "published"),
    )

class UserProfile(AbstractUser):
    pass

class Article(models.Model):
    class Meta:
        verbose_name = _("Article")
        verbose_name_plural = _("Articles")

    title = models.CharField(_("title"), max_length=100)
    content = models.TextField(_("content"), blank=True, default="")
    word_count = models.IntegerField(_("word_count"), blank=True, default="")
    twitter_post = models.TextField(_("twitter_post"), blank=True, default="")
    status = models.CharField(
        max_length=20,
        choices=ARTICLE_STATUS,
        default="draft",
    )
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)
    creator = models.ForeignKey(settings.AUTH_USER_MODEL, 
                                verbose_name=_("creator"), 
                                on_delete=models.CASCADE, 
                                related_name="articles")

    def save(self, *args, **kwargs):
        text = re.sub(r"<[^>]*>", "", self.content).replace("&nbsp", " ")
        self.word_count = len(re.findall(r"\b\w+\b", text)) 
        super().save(*args, **kwargs)



