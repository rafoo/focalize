#**********************************************************************#
#                                                                      #
#                        FoCaLize compiler                             #
#                                                                      #
#            Fran�ois Pessaux                                          #
#            Pierre Weis                                               #
#            Damien Doligez                                            #
#                                                                      #
#                               LIP6  --  INRIA Rocquencourt           #
#                                                                      #
#  Copyright 2008 LIP6 and INRIA                                       #
#  Distributed only by permission.                                     #
#                                                                      #
#**********************************************************************#

# $Id: Makefile,v 1.8 2012-10-15 14:59:24 pessaux Exp $

# Makefile for algebra structures implementations

ROOT_DIR=../../../..

LIB_INSTALL_DIR=$(LIB_DIR)/$(PROJECT_NAME_FULL)

FOCALIZE_COMPILER=$(ROOT_DIR)/src/toplevel/focalizec

STDLIB_DIR=../../stdlib

FOCALIZEC=../../toplevel/focalizec
FOCALIZEDEP=../../focalizedep/focalizedep

FOCALIZE_COMP_FLAGS=-no-stdlib-path -I $(STDLIB_DIR) -coq-version $(COQ_VERSION)

CAML_FLAGS=-w A -warn-error $(WARN_ERROR) -dtypes
CAML_INCLUDES=-I $(STDLIB_DIR)

ZENON_LIB_DIR= $(shell $(ZENON) -where)

ifeq ($(shell test "$(COQ_VERSION)" != "" -a "$(COQ_VERSION)" \< "8.5"; echo $$?),0)
  COQ_INCLUDES=-I $(ZENON_LIB_DIR) -I $(STDLIB_DIR)
else
  COQ_INCLUDES=-Q $(ZENON_LIB_DIR) "" -Q $(STDLIB_DIR) ""
endif

include $(ROOT_DIR)/Makefile.common

FOCALIZE_SRC=\
 pair.fcl\
 peano.fcl

FOCALIZE_FOS=$(FOCALIZE_SRC:.fcl=.fo)
FOCALIZE_MLS=$(FOCALIZE_SRC:.fcl=.ml)

FOCALIZE_CMIS=$(FOCALIZE_SRC:.fcl=.cmi)

FOCALIZE_BYT_OBJS=$(FOCALIZE_MLS:.ml=.cmo)
FOCALIZE_BIN_OBJS=$(FOCALIZE_BYT_OBJS:.cmo=.cmx)

FOCALIZE_ZVS=$(FOCALIZE_SRC:.fcl=.zv)
FOCALIZE_VS=$(FOCALIZE_ZVS:.zv=.v)
FOCALIZE_VOS=$(FOCALIZE_VS:.v=.vo)

ifneq ($(SKCHECK),)
ifneq ($(DKCHECK),)
ifneq ($(ZENONM),)
FOCALIZE_ZSKS=$(FOCALIZE_SRC:.fcl=.sk.zv)
FOCALIZE_SKS=$(FOCALIZE_SRC:.fcl=.sk)
FOCALIZE_DKOS=$(FOCALIZE_SKS:.sk=.dko)
DK_INCLUDES=-I $(shell $(ZENONM) -where) -I $(STDLIB_DIR)
FOCALIZE_COMP_FLAGS += -dedukti-code
endif
endif
endif


lib: all

byt:\
 $(FOCALIZE_MLS)\
 $(FOCALIZE_ZVS)\
 $(FOCALIZE_BYT_OBJS)\
 $(FOCALIZE_VS) $(FOCALIZE_VOS)\
 $(FOCALIZE_SKS) $(FOCALIZE_DKOS)

bin:\
 $(EXTERNAL_BIN_OBJS) $(EXTERNAL_VOS)\
 $(FOCALIZE_MLS)\
 $(FOCALIZE_ZVS)\
 $(FOCALIZE_BIN_OBJS)\
 $(FOCALIZE_VS) $(FOCALIZE_VOS)\
 $(FOCALIZE_SKS) $(FOCALIZE_DKOS)


install:
	@$(MKDIR) $(INSTALL_LIB_DIR) &&\
	if [ "$(FOCALIZE_FOS)" != "" ] ; then\
	  echo "Installing (FoCaLize) compiled certified libs." &&\
	  $(CP) $(FOCALIZE_FOS) $(INSTALL_LIB_DIR)/;\
	fi &&\
	if [ "$(FOCALIZE_CMIS)" != "" ] ; then\
	  echo "Installing (OCaml interface) compiled certified libs." &&\
	  $(CP) $(FOCALIZE_CMIS) $(INSTALL_LIB_DIR)/;\
	fi &&\
	if [ "$(FOCALIZE_BYT_OBJS)" != "" ] ; then\
	  echo "Installing (OCaml bytecode) compiled certified libs." &&\
	  $(CP) $(FOCALIZE_BYT_OBJS) $(INSTALL_LIB_DIR)/;\
	fi &&\
	if [ "$(FOCALIZE_BIN_OBJS)" != "" ] ; then\
	  echo "Installing (OCaml native) compiled certified libs." &&\
	  $(CP) $(FOCALIZE_BIN_OBJS) $(INSTALL_LIB_DIR)/;\
	fi &&\
	if [ "$(FOCALIZE_VOS)" != "" ] ; then\
	  echo "Installing (Coq) compiled certified libs." &&\
	  $(CP) $(FOCALIZE_VOS) $(INSTALL_LIB_DIR)/;\
	fi &&\
	if [ "$(FOCALIZE_DKOS)" != "" ] ; then\
	  echo "Installing (Dedukti) compiled certified libs." &&\
	  $(CP) $(FOCALIZE_DKOS) $(INSTALL_LIB_DIR)/;\
	fi

clean:
	$(RM) $(FOCALIZE_FOS) $(FOCALIZE_MLS) $(FOCALIZE_ZVS) $(FOCALIZE_VS)
	$(RM) $(FOCALIZE_BYT_OBJS) $(FOCALIZE_BIN_OBJS) $(FOCALIZE_VOS) $(FOCALIZE_DKOS)
	$(RM) $(FOCALIZE_CMIS) *.annot *.glob *.fcd *.pfc .depend
	$(RM) *.cm* *.o *.a *.annot *.out *.output *.bin *.byt *.vo *.zv *.dko *.sk.*

depend: .depend

# No need to call skdep because there are no external sk files
.depend:
	$(CAMLDEP) *.mli *.ml > ./.depend
	$(FOCALIZEDEP) *.fcl >> ./.depend

-include .depend
