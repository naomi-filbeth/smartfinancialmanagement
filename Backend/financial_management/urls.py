from django.urls import path
from .views import UserProductListCreate, UserSaleListCreate, UserTopSellingProductList, UserFinancialSummary

urlpatterns = [
    path('/products/', UserProductListCreate.as_view(), name='user_products'),
    path('/sales/', UserSaleListCreate.as_view(), name='user_sales'),
    path('/top-selling-products/', UserTopSellingProductList.as_view(), name='user_top_selling_products'),
    path('/financial-summary/', UserFinancialSummary.as_view(), name='user_financial_summary'),
]