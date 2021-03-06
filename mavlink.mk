# -*- Mode: makefile-gmake; indent-tabs-mode: t; tab-width: 2 -*-
#
# Makefile --- Generate new MAVLink message parsers/serializers for the GCS and
# SMACCMPilot.
#
# Copyright (C) 2013, Galois, Inc.
# All Rights Reserved.
#
# This software is released under the "BSD3" license.  Read the file
# "LICENSE" for more information.
#

# ------------------------------------------------------------------------------

MAVLINK_DIR					:= mavlink
SMACCM_MAVLINK_DIR	:= smaccmpilot-stm32f4/src/smaccm-mavlink

MAVLINK_MSG_DEFS		:= $(MAVLINK_DIR)/message_definitions/v1.0

MAVLINK_DEPS				:= $(MAVLINK_MSG_DEFS)/smaccmpilot.xml \
                       $(MAVLINK_MSG_DEFS)/common.xml

MAVLINK_GCS					:= $(MAVLINK_DIR)/pymavlink/mavlinkv10.py

GCS_SCRIPT          := \
	@python ./$(MAVLINK_DIR)/pymavlink/generator/mavgen.py \
        --lang=python \
        --wire-protocol=1.0 \
        --output=./$(MAVLINK_DIR)/pymavlink/mavlinkv10.py \
        ./$(MAVLINK_MSG_DEFS)/smaccmpilot.xml

$(MAVLINK_GCS): $(MAVLINK_DEPS)
	$(GCS_SCRIPT)

SMACCM_SCRIPT      := \
	@python \
    $(SMACCM_MAVLINK_DIR)/ivory-module-generator/pymavlink/generator/smavgen.py \
	 	-o ./$(SMACCM_MAVLINK_DIR)/src/SMACCMPilot/Mavlink/ \
	 	$(MAVLINK_MSG_DEFS)/smaccmpilot.xml

SMAVLINK_MSGS_HS := \
  $(wildcard $(SMACCM_MAVLINK_DIR)/src/SMACCMPilot/Mavlink/Messages/*.hs)

$(SMAVLINK_MSGS_HS): $(MAVLINK_GCS) $(MAVLINK_DEPS)
	$(SMACCM_SCRIPT)
	@touch $@

SMAVLINK_CABAL := $(SMACCM_MAVLINK_DIR)/smaccm-mavlink.cabal

COMMA := ,

SMAV_MODULES := $(patsubst %.hs, \
                  SMACCMPilot.Mavlink.Messages.%$(COMMA), \
                  $(notdir $(SMAVLINK_MSGS_HS)))

$(SMAVLINK_CABAL): $(SMAVLINK_CABAL).in
$(SMAVLINK_CABAL): $(SMAVLINK_MSGS_HS)
$(SMAVLINK_CABAL): $(MAVLINK_DEPS)
$(SMAVLINK_CABAL): $(MAVLINK_GCS)
	@echo "  GEN      $@"
	@sed -e 's/@MODULES@/$(SMAV_MODULES)/g' < $(SMAVLINK_CABAL).in > $(SMAVLINK_CABAL)

	@echo
	@echo "*****************************************************************"
	@echo "smaccm-mavlink library regenerated. Be sure to put new .hs"
	@echo "files generated from new messages under version control."
	@echo "Ignore this message if you have not defined new MAVLink messages"
	@echo "*****************************************************************"
	@echo

# Phony target to force build.
.PHONY: mavlink
mavlink:
	$(GCS_SCRIPT)
	$(SMACCM_SCRIPT)

# vim: set ft=make noet ts=2:
