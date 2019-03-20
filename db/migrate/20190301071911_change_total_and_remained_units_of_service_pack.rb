class ChangeTotalAndRemainedUnitsOfServicePack < ActiveRecord::Migration[5.1]
  def change
  	  	change_column :service_packs, :total_units, :float
  	  	change_column :service_packs, :remained_units, :float
  end
end
