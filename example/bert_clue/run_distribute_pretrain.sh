#!/bin/bash
# Copyright 2020 Huawei Technologies Co., Ltd
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
# http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
# ============================================================================

echo "=============================================================================================================="
echo "Please run the scipt as: "
echo "sh run_distribute_pretrain.sh DEVICE_NUM EPOCH_SIZE DATA_DIR SCHEMA_DIR MINDSPORE_HCCL_CONFIG_PATH"
echo "for example: sh run_distribute_pretrain.sh 8 40 /path/zh-wiki/ /path/Schema.json /path/hccl.json"
echo "It is better to use absolute path."
echo "=============================================================================================================="

EPOCH_SIZE=$2
DATA_DIR=$3
SCHEMA_DIR=$4

export MINDSPORE_HCCL_CONFIG_PATH=$5
export RANK_TABLE_FILE=$5
export RANK_SIZE=$1

for((i=0;i<RANK_SIZE;i++))
do
    start=`expr $i \* 12`
    export DEVICE_ID=$i
    export RANK_ID=$i
    export DEPLOY_MODE=0
    export GE_USE_STATIC_MEMORY=1
    end=`expr $start \+ 11`
    cmdopt=$start"-"$end

    rm -rf LOG$i
    mkdir ./LOG$i
    cp  *.py ./LOG$i
    cd ./LOG$i || exit
    echo "start training for rank $i, device $DEVICE_ID"
    env > env.log
    taskset -c $cmdopt python ../run_pretrain.py  \
    --distribute="true" \
    --epoch_size=$EPOCH_SIZE \
    --device_id=$DEVICE_ID \
    --device_num=$RANK_SIZE \
    --enable_loop_sink="true" \
    --enable_mem_reuse="true" \
    --enable_save_ckpt="true" \
    --enable_lossscale="true" \
    --do_shuffle="true" \
    --enable_data_sink="true" \
    --data_sink_steps=1 \
    --checkpoint_path="" \
    --save_checkpoint_steps=10000 \
    --save_checkpoint_num=1 \
    --data_dir=$DATA_DIR \
    --schema_dir=$SCHEMA_DIR > log.txt 2>&1 &
    cd ../
done
