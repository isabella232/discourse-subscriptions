# frozen_string_literal: true

module DiscourseSubscriptions
  module Admin
    class PlansController < ::Admin::AdminController
      include DiscourseSubscriptions::Stripe

      before_action :set_api_key

      def index
        begin
          plans = ::Stripe::Price.list(product_params)

          render_json_dump plans.data

        rescue ::Stripe::InvalidRequestError => e
          render_json_error e.message
        end
      end

      def create
        begin
          plan = ::Stripe::Price.create(
            nickname: params[:nickname],
            unit_amount: params[:amount],
            recurring: {
              interval: params[:interval],
            },
            product: params[:product],
            currency: params[:currency],
            active: params[:active],
            metadata: {
              group_name: params[:metadata][:group_name],
              trial_period_days: params[:trial_period_days]
            }
          )

          render_json_dump plan

        rescue ::Stripe::InvalidRequestError => e
          render_json_error e.message
        end
      end

      def show
        begin
          plan = ::Stripe::Price.retrieve(params[:id])

          if plan[:metadata] && plan[:metadata][:trial_period_days]
            trial_days = plan[:metadata][:trial_period_days]
          elsif plan[:recurring] && plan[:recurring][:trial_period_days]
            trial_days = plan[:recurring][:trial_period_days]
          end

          serialized = plan.to_h.merge(trial_period_days: trial_days, currency: plan[:currency].upcase)

          render_json_dump serialized

        rescue ::Stripe::InvalidRequestError => e
          render_json_error e.message
        end
      end

      def update
        begin
          plan = ::Stripe::Price.update(
            params[:id],
            nickname: params[:nickname],
            active: params[:active],
            metadata: {
              group_name: params[:metadata][:group_name],
              trial_period_days: params[:trial_period_days]
            }
          )

          render_json_dump plan

        rescue ::Stripe::InvalidRequestError => e
          render_json_error e.message
        end
      end

      private

      def product_params
        { product: params[:product_id] } if params[:product_id]
      end
    end
  end
end
