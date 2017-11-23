##
#===================================================
# \copyright     2014-2015
#                Siemens Product Lifecycle Management Software Inc.
#                All Rights Reserved.
#===================================================
##

#==================================================
#
##
# Project:       E2S/IEISS/IIM
# @file          sap_get_materialdata_setPV.tcl
##
# jk, 20120724

# Description, comment, flavour.
::TestScript::setScriptDesc "SAP get Material Master Data_setPV"
::TestScript::setScriptComment "Use this method to read detailed information about an existing SAP material master."
::TestScript::setScriptFlavour "T4S"
catch {
  ::TestScript::setScriptCategoryList [list "Material Master"]
}

# Gui.
set materialNumberVar [::TestScript::defineScriptParamText "MatNo" "Material Number" -required]
set plantIdVar [::TestScript::defineScriptParamText "Plant" "Plant"]
set companyCodeVar [::TestScript::defineScriptParamText "Comp_Code" "Company Code"]
set valuationAreaVar [::TestScript::defineScriptParamText "Val_Area" "Valuation Area"]
set valuationTypeVar [::TestScript::defineScriptParamText "Val_Type" "Valuation Type"]
set storageLocationVar [::TestScript::defineScriptParamText "Storage_Loc" "Storage Location"]
set salesOrganizationVar [::TestScript::defineScriptParamText "SalesOrg" "Sales Organization"]
set distributionChannelVar [::TestScript::defineScriptParamText "Distr_Channel" "Distribution Channel"]
set warehouseNumberVar [::TestScript::defineScriptParamText "Whse_Number" "Warehouse Number / Warehouse Complex"]
set storageTypeVar [::TestScript::defineScriptParamText "Storage_Type" "Storage Type"]
set useJcoVar [::TestScript::defineScriptParamCombo "UseJco" "Use JCO" \
                [list "FALSE" "TRUE"] \
                -external \
                [list "false" "true"]]
::TestScript::setScriptGui [list $materialNumberVar \
                                 $plantIdVar \
                                 $companyCodeVar \
                                 $valuationAreaVar \
                                 $valuationTypeVar \
                                 $storageLocationVar \
                                 $salesOrganizationVar \
                                 $distributionChannelVar \
                                 $warehouseNumberVar \
                                 $storageTypeVar \
                                 $useJcoVar]
::TestScript::checkTestParam $argv

set Action TEST
set Filter ""

set MaterialMaster ""
set Plant ""
set Comp_Code ""
set Val_Area ""
set Val_Type ""
set Storage_Loc ""
set SalesOrg ""
set Distr_Channel ""
set Whse_Number ""
set Storage_Type ""
#
set UseJco "FALSE"
#
if {[llength $argv] > 1} {
  foreach {Parameter Value} [lrange $::argv 1 end] {
    switch -exact -- $Parameter {
      -MatNo  {set MaterialMaster $Value}
      -Plant  {set Plant $Value}
      -Comp_Code  {set Comp_Code $Value}
      -Val_Area  {set Val_Area $Value}
      -Val_Type  {set Val_Type $Value}
      -Storage_Loc  {set Storage_Loc $Value}
      -SalesOrg  {set SalesOrg $Value}
      -Distr_Channel  {set Distr_Channel $Value}
      -Whse_Number  {set Whse_Number $Value}
      -Storage_Type  {set Storage_Type $Value}
      -UseJco {set UseJco $Value}
      +language {;# ignore}
    }
  }
} else {
  puts "wrong usage: [lindex $argv 0] -MatNo MaterialMaster -Plant ?Plant? -UseJco ?JCO?"
  exit 0
}


namespace eval ::T4S::TEST::MM::SAPMaterialData {

  set depends { }
  set title {
    Get SAPMaterialData  ...
  }
  set description {
    # Set general SOA constants
  }

  namespace eval checkSapConnection {
    set depends {
    }
    set title {
      connect SAP
    }
    set description {
      # Set general SOA constants
    }
    proc code {} {
      puts "############################################################################################################"
      puts $::T4S::TEST::MM::SAPMaterialData::title
      puts "############################################################################################################"
      set Status [::T4S::CONNECTION2SAP::testSAPLogin]
      puts "############################################################################################################"
    }
    proc verify {} {
      assertEquals "OK" $Status
    }
  }

  namespace eval GetMaterialMasterData {
    set depends { checkSapConnection }
    set title {
      Performing step -> GetMaterialMasterData ...
    }
    set description {
      # Set general SOA constants
    }
    proc code {} {
      set SAPVersion [::TPSAP::getReleaseInfo]

      if {$SAPVersion == "UNKNOWNRELEASE" } {
        set Status "NO_LOGIN"
      } elseif {$SAPVersion == "46C" } {
        set Status [::TPSAP::MM::getMaterialMasterInfo $MaterialMaster $Plant]
        set Status [::TPSAP::MM::getMaterialMasterInfoRfc $MaterialMaster]
      } else {
        if { $UseJco == "TRUE" } {
        #
        # Activate JCO for this call
        #
        set ::TPSAP::MM::UseJCO(BAPI_MATERIAL_GET_ALL) ""
        } else {
          catch { unset ::TPSAP::MM::UseJCO(BAPI_MATERIAL_GET_ALL) }
        }
        set Status [::TPSAP::MM::getAllMaterialMasterInfos $MaterialMaster $Plant $Comp_Code $Val_Area $Val_Type $Storage_Loc $SalesOrg $Distr_Channel $Whse_Number $Storage_Type]
      }
    }
    proc verify {} {
      assertEquals "OK" $Status
    }
  }

  namespace eval PrintSAPMaterialData {
    set depends { GetMaterialMasterData }
    set title {
      Performing step -> PrintSAPMaterialData ...
    }
    set description {
      # Set general SOA constants
    }
    proc code {} {
      foreach in [lsort [array names ::SapMatDat]] {
        puts "++++++++++ SapMatDat($in) = $::SapMatDat($in)"
      }

      set ind [array names SapMatDat $MaterialMaster:MATERIALDESCRIPTION:MATL_DESC:1]
      if {[llength $ind] > 0} {set Status OK} else {set Status ERROR}
    }
    proc verify {} {
      assertEquals "OK" $Status
    }
  }

  namespace eval MaterialMasterAvailability {
    set depends { MaterialMasterReadAllSingle }
    set title {
      Performing step -> MaterialMasterAvailability ...
    }
    set description {
      # Set general SOA constants
    }
    proc code {} {
      set SAPVersion [::TPSAP::getReleaseInfo]
      puts "Plant - $Plant"
      puts "SAPVersion  - $SAPVersion "
      if {[string length $Plant] > 0} {
        if {$SAPVersion == "46C" } {
          set Base_UoM [::T4S::TC::MAPPING::SAPFieldMapping MaterialMaster $MaterialMaster MARA-MEINS]
        } else {
          set Base_UoM [::T4S::TC::MAPPING::SAPFieldMapping MaterialMaster $MaterialMaster CLIENTDATA:BASE_UOM]
        }
        set Status [::TPSAP::MM::checkMaterialMasterAvailability $MaterialMaster $Plant $Base_UoM]
        puts "+++ AvailabilityCheck ++++++++ $Status"
        puts "+++ Available Items in Plant [::T4S::TC::MAPPING::SAPFieldMapping MaterialMaster $MaterialMaster AV_QTY_PLT]"
      }
    }
    proc verify {} {
      #assertEquals "OK" $Status
      assertDiffers "ERROR" $Status

    }
  }

  namespace eval MaterialMasterReadAllSingle {
    set depends { PrintSAPMaterialData }
    set title {
      Performing step -> MaterialMasterReadAllSingle ...
    }
    set description {
      # Set general SOA constants
    }
    proc code {} {
      puts "+++ MaterialData with MATERIAL_READ_ALL_SINGLE Start ++++++++"
      set ::SAPDat(READSINGLE:SCHLUESSEL:MATNR) $MaterialMaster
      set ::SAPDat(READSINGLE:SCHLUESSEL:WERKS) $Plant
      # Data like ...
      set ::SAPDat(READSINGLE:SCHLUESSEL:LGORT) $Storage_Loc
      set ::SAPDat(READSINGLE:SCHLUESSEL:LGTYP) $Storage_Type
      set ::SAPDat(READSINGLE:SCHLUESSEL:LGNUM) $Whse_Number
      set ::SAPDat(READSINGLE:SCHLUESSEL:BWKEY) $Val_Area
      set ::SAPDat(READSINGLE:SCHLUESSEL:BWTAR) $Val_Type
      set ::SAPDat(READSINGLE:SCHLUESSEL:VKORG) $SalesOrg
      set ::SAPDat(READSINGLE:SCHLUESSEL:VTWEG) $Distr_Channel
      # ... could be added to get more detailed information about the MaterialMaster

      set Status [::TPSAP::MM::getAllMaterialMasterInfosReadSingle ]
      puts "++++++++++ Status  = $Status "

      foreach in [lsort [array names ::SapMatDat]] {
        puts "++++++++++ SapMatDat($in) = $::SapMatDat($in)"
      }
      puts "+++ MaterialData with MATERIAL_READ_ALL_SINGLE End ++++++++"
	  
	  puts "+++ ProductionVersion Testing Start ++++++++"
		#
		set rc [::TPSAP::MM::readProductionVersion $MaterialMaster $Plant]
		#
		puts " "
		puts "::TPSAP::MM::readProductionVersion finished with >$rc<"
		puts " "
		#
		#
		foreach elem [::T4X::CORE::sortIndexedInterfaceTable [array names ::sap_result_array]] {
		  puts "::sap_result_array($elem) = $::sap_result_array($elem)"
		}
		
		puts " "
		puts "Will work with maintainProductionVersion() to create/update PV"
		puts " "
		#$Plant
		set ::SAPDat(ProdVersion:MKAL:WERKS) $Plant
		#$MatNr
		set ::SAPDat(ProdVersion:MKAL:MATNR) $MaterialMaster
		set ::SAPDat(ProdVersion:MKAL_EXPAND:MATNR) $::SAPDat(ProdVersion:MKAL:MATNR)
		#$ProdVers
		puts "::sap_result_array(E_MKAL:VERID:1) = $::sap_result_array($elem)"
		set ::SAPDat(ProdVersion:MKAL_EXPAND:VERID) "7"
		#$ShortText
		set ::SAPDat(ProdVersion:MKAL_EXPAND:TEXT1) "TaskList+BOM were created from T4S!"
		
		# set ValidFrom                [clock format [clock seconds] -format "%d.%m.%Y"]
		set ValidFrom                "01.01.2012"
        set ValidTo                  "31.12.9999"
		
		#$ValidFrom
		set ::SAPDat(ProdVersion:MKAL_EXPAND:ADATU) $ValidFrom
		#$ValidTo
		set ::SAPDat(ProdVersion:MKAL_EXPAND:BDATU) $ValidTo
		#Set Task Lists ::sap_result_array(E_MKAL:PLNNR:1) = 56067772; ::sap_result_array(E_MKAL:PLNTY:1) = N; ::sap_result_array(E_MKAL:ALNAL:1) = 01
		set ::SAPDat(ProdVersion:MKAL_EXPAND:PLNTY) "N"
		set ::SAPDat(ProdVersion:MKAL_EXPAND:PLNNR) "56067772"
		set ::SAPDat(ProdVersion:MKAL_EXPAND:ALNAL) "01"
		
		#Set BOMs ::sap_result_array(E_MKAL:STLAL:1) = 01;::sap_result_array(E_MKAL:STLAN:1) = 1
		set ::SAPDat(ProdVersion:MKAL_EXPAND:STLAL) "01"
		set ::SAPDat(ProdVersion:MKAL_EXPAND:STLAN) "1"
		#
		set rc [::TPSAP::MM::maintainProductionVersion]
		#
		puts " "
		puts "::TPSAP::MM::maintainProductionVersion finished with >$rc<"
		puts " "
		puts " Read again to check updates!"
		#
		set rc [::TPSAP::MM::readProductionVersion $MaterialMaster $Plant]
		#
		puts " "
		puts "::TPSAP::MM::readProductionVersion finished with >$rc<"
		puts " "
		#
		#
		foreach elem [::T4X::CORE::sortIndexedInterfaceTable [array names ::sap_result_array]] {
		  puts "::sap_result_array($elem) = $::sap_result_array($elem)"
		}
	  puts "+++ ProductionVersion Testing End ++++++++"
    }
  }
}


switch -exact -- $Action {
  TEST {
    ::T4X::TestingSupport::executeTests ::T4S::TEST::MM::SAPMaterialData ::T4S::TEST::MM::SAPMaterialData testResults $Filter

    ::T4X::TestingSupport::putTestReport testResults
    ::T4X::TestingSupport::logTestReport testResults "/tmp/[tpco_getHostName]/[tpco_shmget share CONFIG.APPSRV.INSTNAME]/SAP_GET_MM.log"
  }
  TEACH {
    ::T4X::TestingSupport::putLessons :::T4S::TEST::MM::SAPMaterialData::GetMaterialMasterData ::T4S::TEST::MM::SAPMaterialData::PrintSAPMaterialData $Filter
  }
  OVERVIEW {
    ::T4X::TestingSupport::putOverview ::T4S::TEST::MM::SAPMaterialData::GetMaterialMasterData ::T4S::TEST::MM::SAPMaterialData::PrintSAPMaterialData $Filter
  }
  CODE {
    ::T4X::TestingSupport::putCode ::T4S::TEST::MM::SAPMaterialData::GetMaterialMasterData ::T4S::TEST::MM::SAPMaterialData::PrintSAPMaterialData $Filter
  }
}

exit  0
