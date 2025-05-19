from rest_framework import serializers
from .models import Product, Sale

class ProductSerializer(serializers.ModelSerializer):
    class Meta:
        model = Product
        fields = ['id', 'name', 'price', 'cost', 'stock']

class SaleSerializer(serializers.ModelSerializer):
    product = serializers.PrimaryKeyRelatedField(
        queryset=Product.objects.all(),
        error_messages={
            'does_not_exist': 'Product with this ID does not exist.',
            'invalid': 'Invalid product ID provided.'
        }
    )

    class Meta:
        model = Sale
        fields = ['id', 'product', 'quantity', 'price', 'cost', 'date']
        extra_kwargs = {
            'user': {'read_only': True},
            'price': {'error_messages': {'invalid': 'Price must be a valid number.'}},
            'cost': {'error_messages': {'invalid': 'Cost must be a valid number.'}},
            'quantity': {'error_messages': {'invalid': 'Quantity must be a valid integer.'}},
            'date': {'error_messages': {'invalid': 'Date must be in YYYY-MM-DD format.'}}
        }

    def validate(self, data):
        user = self.context['request'].user
        product = data.get('product')
        if product.user != user:
            raise serializers.ValidationError('Product does not belong to this user.')
        return data

    def create(self, validated_data):
        validated_data['user'] = self.context['request'].user
        return super().create(validated_data)

class TopSellingProductSerializer(serializers.Serializer):
    name = serializers.CharField(max_length=100)
    quantity = serializers.IntegerField()

    class Meta:
        fields = ['name', 'quantity']