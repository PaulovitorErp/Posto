#include "protheus.ch"
#include "topconn.ch"

/*/{Protheus.doc} TRETR025
Relatório Compensação de Valores

@type function
@author danilo
@since 13/10/2023
@version 1.0
/*/
User Function TRETR025()

	Local oReport

	oReport:= ReportDef()
	oReport:PrintDialog()

Return

Static Function ReportDef()

	Local oReport
	Local oSection1, oSection2
	Local cTitle    := "Relatorio Compensação de Valores"
	Local cAliasQry := GetNextAlias()

	oReport:= TReport():New("TRETR025",cTitle,"TRETR025",{|oReport| PrintReport(oReport,cAliasQry)},"Este relatório apresenta uma relação de Compensação de Valores.")
	oReport:SetPortrait()
	oReport:HideParamPage()
	oReport:SetUseGC(.F.)

	U_uAjusSx1("TRETR025","01","Filial de ?","","","mv_ch1","C",len(cFilAnt),0,0,"G","","XM0","","","mv_par01","","",""," ","","","","","","","","","","","","",{"", ""}, {"",""}, {"",""})
	U_uAjusSx1("TRETR025","02","Filial até ?","","","mv_ch2","C",len(cFilAnt),0,0,"G","","XM0","","","mv_par02","","","","","","","","","","","","","","","","",{"", ""}, {"",""}, {"",""})
	U_uAjusSx1("TRETR025","03","Data de ?","","","mv_ch3","D",8,0,0,"G",""," ","","","mv_par03","","",""," ","","","","","","","","","","","","",{"", ""}, {"",""}, {"",""})
	U_uAjusSx1("TRETR025","04","Data até ?","","","mv_ch4","D",8,0,0,"G",""," ","","","mv_par04","","","","","","","","","","","","","","","","",{"", ""}, {"",""}, {"",""})
    U_uAjusSx1("TRETR025","05","Num.Compensação de ?","","","mv_ch5","C",TamSX3("UC0_NUM")[1],0,0,"G",""," ","","","mv_par05","","",""," ","","","","","","","","","","","","", {"", ""}, {"",""}, {"",""})
    U_uAjusSx1("TRETR025","06","Num.Compensação ate ?","","","mv_ch6","C",TamSX3("UC0_NUM")[1],0,0,"G",""," ","","","mv_par06","","",""," ","","","","","","","","","","","","", {"", ""}, {"",""}, {"",""})
	U_uAjusSx1("TRETR025","07","Cliente ?","","","mv_ch7","C",TamSX3("UC0_CLIENT")[1],0,0,"G","","SA1","","","mv_par07","","",""," ","","","","","","","","","","","","", {"", ""}, {"",""}, {"",""})
	U_uAjusSx1("TRETR025","08","Loja ?","","","mv_ch8","C",TamSX3("UC0_LOJA")[1],0,0,"G",""," ","","","mv_par08","","","","","","","","","","","","","","","","",{"", ""}, {"",""}, {"",""})
    U_uAjusSx1("TRETR025","09","Placa ?","","","mv_ch9","C",TamSX3("UC0_PLACA")[1],0,0,"G",""," ","","","mv_par09","","",""," ","","","","","","","","","","","","", {"", ""}, {"",""}, {"",""})
    U_uAjusSx1("TRETR025","10","Serie de ?","","","mv_cha","C",TamSX3("L1_SERIE")[1],0,0,"G",""," ","","","mv_par10","","",""," ","","","","","","","","","","","","", {"", ""}, {"",""}, {"",""})
	U_uAjusSx1("TRETR025","11","Nota Fiscal de ?","","","mv_chb","C",TamSX3("L1_DOC")[1],0,0,"G",""," ","","","mv_par11","","","","","","","","","","","","","","","","",{"", ""}, {"",""}, {"",""})
    U_uAjusSx1("TRETR025","12","Serie até ?","","","mv_chc","C",TamSX3("L1_SERIE")[1],0,0,"G",""," ","","","mv_par12","","",""," ","","","","","","","","","","","","", {"", ""}, {"",""}, {"",""})
	U_uAjusSx1("TRETR025","13","Nota Fiscal até ?","","","mv_chd","C",TamSX3("L1_DOC")[1],0,0,"G",""," ","","","mv_par13","","","","","","","","","","","","","","","","",{"", ""}, {"",""}, {"",""})
    U_uAjusSx1("TRETR025","14","Tipo de Impressão?","","","mv_che","N",1,0,0,"C","","","","","mv_par14","Analítico","","","","Síntético","","","","","","","","","","","",{"", ""},{"", ""},{"", ""})

	Pergunte(oReport:GetParam(),.F.)

	oSection1 := TRSection():New(oReport,"Compensação de Valores",{"UC0","SA1","SL1"})
	oSection1:SetHeaderPage(.T.)
	oSection1:SetHeaderSection(.T.)

	TRCell():New(oSection1, "UC0_FILIAL"    , "UC0", /*cTitulo*/, /*cPicture*/, /*nTamanho*/)
	TRCell():New(oSection1, "UC0_NUM"       , "UC0", /*cTitulo*/, /*cPicture*/, /*nTamanho*/)
	TRCell():New(oSection1, "UC0_DATA"      , "UC0", /*cTitulo*/, /*cPicture*/, /*nTamanho*/)
	TRCell():New(oSection1, "UC0_HORA"      , "UC0", /*cTitulo*/, /*cPicture*/, /*nTamanho*/)
	TRCell():New(oSection1, "UC0_PLACA"     , "UC0", /*cTitulo*/, /*cPicture*/, /*nTamanho*/)
	TRCell():New(oSection1, "UC0_CLIENT"    , "UC0", /*cTitulo*/, /*cPicture*/, TamSX3("UC0_CLIENT")[1]+TamSX3("UC0_LOJA")[1]+2)
	TRCell():New(oSection1, "A1_NOME"       , "SA1", /*cTitulo*/, /*cPicture*/, 25) //para truncar nome
	TRCell():New(oSection1, "UC0_PDV"       , "UC0", /*cTitulo*/, /*cPicture*/, /*nTamanho*/)
	TRCell():New(oSection1, "UC0_OPERAD"    , "UC0", /*cTitulo*/, /*cPicture*/, /*nTamanho*/)
	TRCell():New(oSection1, "UC0_VLTOT"     , "UC0", /*cTitulo*/, /*cPicture*/, /*nTamanho*/)
	TRCell():New(oSection1, "UC0_DOC"       , "UC0", /*cTitulo*/, /*cPicture*/, /*nTamanho*/)
	TRCell():New(oSection1, "UC0_SERIE"     , "UC0", /*cTitulo*/, /*cPicture*/, /*nTamanho*/)
	TRCell():New(oSection1, "L1_VLRTOT"	    , "SL1", "Valor NF"/*cTitulo*/, /*cPicture*/, /*nTamanho*/)

    oSection2 := TRSection():New(oSection1,"Formas de pagamento",{"UC1"})
    oSection2:SetHeaderPage(.T.)
    oSection2:SetHeaderSection(.T.) 
    oSection2:nLeftMargin := 3 

    TRCell():New(oSection2, "TIPOMOV"     , "UC1", "Tipo Mov."/*cTitulo*/, /*cPicture*/, 8 /*nTamanho*/)
    TRCell():New(oSection2, "UC1_FORMA"   , "UC1", /*cTitulo*/, /*cPicture*/, 20 /*nTamanho*/)
	TRCell():New(oSection2, "DOCUMENTO"   , "UC1", "Num.Documento"/*cTitulo*/, "@!"/*cPicture*/, 40/*nTamanho*/)
	TRCell():New(oSection2, "EMITENTE"    , "UC1", "Emitente (sacado)"/*cTitulo*/, "@!"/*cPicture*/, 40/*nTamanho*/)
	TRCell():New(oSection2, "UC1_VALOR"   , "UC1", /*cTitulo*/, /*cPicture*/, /*nTamanho*/)
	TRCell():New(oSection2, "UC1_VENCTO"  , "UC1", /*cTitulo*/, /*cPicture*/, /*nTamanho*/)

Return(oReport)

Static Function PrintReport(oReport,cAliasQry)
	
	Local oSection1		:= oReport:Section(1)
    Local oSection2		:= oReport:Section(1):Section(1)
	Local cQry          := ""

	If Empty(Select("SM0"))
		OpenSM0(cEmpAnt)
	EndIf

	cQry += " SELECT R_E_C_N_O_ RECUC0 "
	cQry += " FROM "+RetSQLName("UC0")+" UC0 "
	cQry += " WHERE UC0.D_E_L_E_T_ = ' '"
	cQry += " AND UC0.UC0_FILIAL BETWEEN "+ValToSQL(MV_PAR01)+" AND "+ValToSQL(MV_PAR02)
	cQry += " AND UC0.UC0_DATA BETWEEN "+ValToSQL(MV_PAR03)+" AND "+ValToSQL(MV_PAR04)
	cQry += " AND UC0.UC0_NUM BETWEEN "+ValToSQL(MV_PAR05)+" AND "+ValToSQL(MV_PAR06)
    if !empty(MV_PAR07)
        cQry += " AND UC0.UC0_CLIENT = "+ValToSQL(MV_PAR07)
        cQry += " AND UC0.UC0_LOJA = "+ValToSQL(MV_PAR08)
    endif
    if !empty(MV_PAR09)
        cQry += " AND UC0.UC0_PLACA = "+ValToSQL(MV_PAR09)
    endif
	cQry += " AND UC0.UC0_SERIE BETWEEN "+ValToSQL(MV_PAR10)+" AND "+ValToSQL(MV_PAR12)
	cQry += " AND UC0.UC0_DOC BETWEEN "+ValToSQL(MV_PAR11)+" AND "+ValToSQL(MV_PAR13)
    cQry += " ORDER BY UC0_DATA, UC0_HORA"
    cQry := ChangeQuery(cQry)
	
	MPSysOpenQuery(cQry,cAliasQry)

    if (cAliasQry)->(EOF())
        Return(.T.)
    endif

    oSection1:Init()

    SA1->(DbSetOrder(1)) //cliente+loja
    SL1->(DbSetOrder(2)) //L1_FILIAL+L1_SERIE+L1_DOC+L1_PDV
    UC1->(DbSetOrder(1)) //UC1_FILIAL+UC1_NUM+UC1_FORMA+UC1_SEQ
    UF2->(DbSetOrder(3)) //UF2_FILIAL+UF2_DOC+UF2_SERIE+UF2_PDV

	While !oReport:Cancel() .And. (cAliasQry)->(!EOF())

		oReport:IncMeter()
		If oReport:Cancel()
			Exit
		EndIf
        
        UC0->(DbGoTo((cAliasQry)->RECUC0))
        SA1->(DbSeek(xFilial("SA1")+UC0->UC0_CLIENT+UC0->UC0_LOJA))
        if !empty(UC0->UC0_DOC)
            SL1->(DbSeek(UC0->UC0_FILIAL+UC0->UC0_SERIE+UC0->UC0_DOC))
        else
            SL1->(DbSeek("XXXX"))//para ir a Eof
        endif
        
        oSection1:PrintLine()

        if MV_PAR14 == 1 //analitico
            
            oSection2:Init()

            //parcelas de entrada
            if UC1->(DbSeek(UC0->UC0_FILIAL+UC0->UC0_NUM))
                While UC1->(!Eof()) .AND.  UC1->UC1_FILIAL+UC1->UC1_NUM == UC0->UC0_FILIAL+UC0->UC0_NUM

                    oSection2:Cell("TIPOMOV"):SetValue("ENTRADA")
                    oSection2:Cell("UC1_FORMA"):SetValue(Alltrim(UC1->UC1_FORMA)+"-"+SubStr(Posicione("SX5",1,xFilial("SX5")+'24'+Alltrim(UC1->UC1_FORMA),"X5_DESCRI"),1,17))

                    if Alltrim(UC1->UC1_FORMA) == "CF" //carta frete
                        oSection2:Cell("DOCUMENTO"):SetValue(Alltrim(UC1->UC1_CFRETE))
                        oSection2:Cell("EMITENTE"):SetValue(Alltrim(UC1->UC1_CGC)+" "+Posicione("SA1",3,xFilial("SA1")+UC1->UC1_CGC,"A1_NOME"))
                    endif

                    if Alltrim(UC1->UC1_FORMA) == "CH" //Cheque
                        oSection2:Cell("DOCUMENTO"):SetValue("Bc:"+Alltrim(UC1->UC1_BANCO)+" Ag:"+Alltrim(UC1->UC1_AGENCI)+" Ct:"+Alltrim(UC1->UC1_CONTA)+" Num:"+Alltrim(UC1->UC1_NUMCH))
                        oSection2:Cell("EMITENTE"):SetValue(Alltrim(UC1->UC1_CGC)+" "+Posicione("SA1",3,xFilial("SA1")+UC1->UC1_CGC,"A1_NOME"))
                    endif

                    if Alltrim(UC1->UC1_FORMA) $ "CC/CD" //cartoes
                        oSection2:Cell("DOCUMENTO"):SetValue("NSU:"+Alltrim(UC1->UC1_NSUDOC)+" AUT:"+Alltrim(UC1->UC1_CODAUT))
                        oSection2:Cell("EMITENTE"):SetValue(UC1->UC1_ADMFIN+"-"+Posicione("SAE",1,xFilial("SAE",UC1->UC1_FILIAL) + UC1->UC1_ADMFIN, "AE_DESC"))
                    endif

                    oSection2:Cell("UC1_VALOR"):SetValue(UC1->UC1_VALOR)
                    oSection2:Cell("UC1_VENCTO"):SetValue(UC1->UC1_VENCTO)

                    oSection2:PrintLine()

                    UC1->(DbSkip())
                enddo

                UC1->(DbSeek("XXXX")) //para ir a Eof
            endif

            //parcelas de saída
            if UC0->UC0_VLDINH > 0
                oSection2:Cell("TIPOMOV"):SetValue("SAÍDA")
                oSection2:Cell("UC1_FORMA"):SetValue("R$-DINHEIRO")
                oSection2:Cell("DOCUMENTO"):SetValue("")
                oSection2:Cell("EMITENTE"):SetValue("")
                oSection2:Cell("UC1_VALOR"):SetValue(UC0->UC0_VLDINH)
                oSection2:Cell("UC1_VENCTO"):SetValue(UC0->UC0_DATA)
                oSection2:PrintLine()
            endif
            if UC0->UC0_VLVALE > 0
                oSection2:Cell("TIPOMOV"):SetValue("SAÍDA")
                oSection2:Cell("UC1_FORMA"):SetValue("VL-VALE HAVER (NCC)")
                oSection2:Cell("DOCUMENTO"):SetValue("")
                oSection2:Cell("EMITENTE"):SetValue("")
                oSection2:Cell("UC1_VALOR"):SetValue(UC0->UC0_VLVALE)
                oSection2:Cell("UC1_VENCTO"):SetValue(UC0->UC0_DATA)
                oSection2:PrintLine()
            endif
            if UC0->UC0_VLCHTR > 0 .AND. UF2->(DbSeek(UC0->UC0_FILIAL+UC0->UC0_NUM+"CMP"))
                While UF2->(!Eof()) .AND.  UF2->UF2_FILIAL+UF2->UF2_DOC+UF2->UF2_SERIE == UC0->UC0_FILIAL+UC0->UC0_NUM+"CMP"
                    oSection2:Cell("TIPOMOV"):SetValue("SAÍDA")
                    oSection2:Cell("UC1_FORMA"):SetValue("CHT-CHEQUE TROCO")
                    oSection2:Cell("DOCUMENTO"):SetValue("Bc:"+Alltrim(UF2->UF2_BANCO)+" Ag:"+Alltrim(UF2->UF2_AGENCI)+" Ct:"+Alltrim(UF2->UF2_CONTA)+" Num:"+Alltrim(UF2->UF2_NUM))
                    oSection2:Cell("EMITENTE"):SetValue("")
                    oSection2:Cell("UC1_VALOR"):SetValue(UF2->UF2_VALOR)
                    oSection2:Cell("UC1_VENCTO"):SetValue(UC0->UC0_DATA)
                    oSection2:PrintLine()

                    UF2->(DbSkip())
                enddo
            endif

            oSection2:Finish()

            oReport:SkipLine()
        endif

		(cAliasQry)->(dbSkip())
	EndDo

	oSection1:Finish()

Return(.T.)
