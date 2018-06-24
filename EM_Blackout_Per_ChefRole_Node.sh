em_onodelist=""
chef_role=""
ROLE=""
node_list=""
#node_list_arr=""
arr_size=""
em_nodelist=""
current_time=$(date '+%Y-%m-%d %H:%M')
if [ -z "$1" ];then
  echo "Please provide the role name $0 chef_role eg: $0 Powertrack or $0 Powertrack RulesEngine-Manager"
else
for chef_role in "$@"
 do
  ROLE=$chef_role
  echo "Blackout Running on Role $ROLE" 
  node_list=`tsocks knife search "role:$ROLE" -i `
  node_list_arr=($node_list)
  arr_size=${#node_list_arr[@]}
  for ((i=0;i<arr_size;i++))
    do
	node_list_arr[i]="${node_list_arr[i]}:host"
      if [ $i -eq 0 ];then 
	    em_nodelist="${node_list_arr[i]}"
	  else
        em_nodelist="$em_nodelist;${node_list_arr[i]}"
      fi
  done
  echo "Blackout running on $ROLE"
  blackout_name="SDP_auto_Blackout_$ROLE_$RANDOM"
  echo "Blackout Name: $blackout_name"
  echo "Nodes list : $em_nodelist"
  emcli create_blackout -name="$blackout_name" -add_targets="${em_nodelist}" -reason="Apps: Application Upgrade" -description="Blackout nodes created by Auto Script" -schedule="frequency:once;start_time:${current_time};tzinfo:specified;tzregion:Asia/Calcutta;duration:1" 
done
fi
