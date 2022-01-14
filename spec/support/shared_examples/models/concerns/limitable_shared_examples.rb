# frozen_string_literal: true

RSpec.shared_examples 'includes Limitable concern' do
  describe 'validations' do
    let(:plan_limits) { create(:plan_limits, :default_plan) }

    it { is_expected.to be_a(Limitable) }

    context 'without plan limits configured' do
      it 'can create new models' do
        expect { subject.save! }.to change { described_class.count }
      end
    end

    context 'with plan limits configured' do
      before do
        plan_limits.update!(subject.class.limit_name => 1)
      end

      it 'can create new models' do
        expect { subject.save! }.to change { described_class.count }
      end

      context 'with an existing model' do
        before do
          subject.dup.save!
        end

        it 'cannot create new models exceeding the plan limits' do
          expect do
            expect { subject.save! }.to raise_error(ActiveRecord::RecordInvalid)
          end
            .not_to change { described_class.count }
          expect(subject.errors[:base]).to contain_exactly("Maximum number of #{subject.class.limit_name.humanize(capitalize: false)} (1) exceeded")
        end
      end
    end
  end
end
