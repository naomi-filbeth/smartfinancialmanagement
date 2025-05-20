from rest_framework import generics, permissions
from rest_framework.response import Response
from rest_framework.exceptions import PermissionDenied
from .models import Product, Sale, TopSellingProduct
from .serializers import ProductSerializer, SaleSerializer, TopSellingProductSerializer
from django.db.models import Sum
from django.utils import timezone
from django.db import transaction

class UserProductListCreate(generics.ListCreateAPIView):
    serializer_class = ProductSerializer
    permission_classes = [permissions.IsAuthenticated]

    def get_queryset(self):
        return Product.objects.filter(user=self.request.user)

    def perform_create(self, serializer):
        serializer.save(user=self.request.user)

class UserSaleListCreate(generics.ListCreateAPIView):
    serializer_class = SaleSerializer
    permission_classes = [permissions.IsAuthenticated]

    def get_queryset(self):
        return Sale.objects.filter(user=self.request.user)

    def perform_create(self, serializer):
        with transaction.atomic():
            sale = serializer.save(user=self.request.user)
            product = sale.product
            quantity_sold = sale.quantity
            if product.stock < quantity_sold:
                raise PermissionDenied("Insufficient stock to complete this sale.")
            product.stock -= quantity_sold
            product.save()


class UserTopSellingProductList(generics.ListAPIView):
    serializer_class = TopSellingProductSerializer
    permission_classes = [permissions.IsAuthenticated]

    def get_queryset(self):
        sales = Sale.objects.filter(user=self.request.user).values('product').annotate(total_quantity=Sum('quantity'))
        top_products = []
        for sale in sales:
            product = Product.objects.get(id=sale['product'], user=self.request.user)
            top_products.append(TopSellingProduct(user=self.request.user, product=product, quantity=sale['total_quantity']))
        return top_products

class UserFinancialSummary(generics.GenericAPIView):
    permission_classes = [permissions.IsAuthenticated]

    def get(self, request, *args, **kwargs):
        user = request.user
        total_sales = Sale.objects.filter(user=user).aggregate(total=Sum('price'))['total'] or 0
        total_cost = Sale.objects.filter(user=user).aggregate(total=Sum('cost'))['total'] or 0
        total_profit = total_sales - total_cost
        return Response({
            'total_sales': float(total_sales),
            'total_cost': float(total_cost),
            'total_profit': float(total_profit)
        })