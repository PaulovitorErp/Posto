#INCLUDE "PROTHEUS.CH"
#INCLUDE "TOTVS.CH"
#INCLUDE "TBICONN.CH"
#INCLUDE "POSCSS.CH"
#INCLUDE "STPOS.CH"
#INCLUDE "FILEIO.CH"
#INCLUDE "TOPCONN.CH"

//#DEFINE CRLF CHR(13)+CHR(10)
#DEFINE nMarcado 1

/*/{Protheus.doc} UPDR2210
Migração de dados do POSTO: 12.1.27 x 12.1.2210

@type function
@author Pablo Nunes
@since 19/07/2023
/*/
User Function UPDR2210()
	Local oStepWiz
	Local oNewPag
	Local oStatus

	Local aSM0 := {}
	Local lRet := .F.

	Private aEmpresas := {}
	Private aTabMigracao := {}
    Private cEmpAnt		:= ""
    Private cFilant		:= ""

	oStepWiz := FWWizardControl():New(,{530,720})
	oStepWiz:ActiveUISteps()

//--------------------------------------------
// Pagina 1 - Boas Vindas
//--------------------------------------------
	oNewPag := oStepWiz:AddStep("1")
	oNewPag:SetStepDescription("Boas Vindas")
	oNewPag:SetConstruction({|oPanel| Etapa1(oPanel)})
	//oNewPag:SetNextAction({|| ValEtapa1()})
	oNewPag:SetCancelAction({||.T.})

//--------------------------------------------
// Pagina 2 - Seleção de Filiais
//--------------------------------------------
	oNewPag := oStepWiz:AddStep("2", {|oPanel| Etapa2(oPanel,@aSM0)})
	oNewPag:SetStepDescription("Seleção de Filiais")
	oNewPag:SetNextAction({|| FWMsgRun(/*oComponent*/,{ || lRet := ValEtapa2() }, Nil, "Validando seleção de Empresa(s)/Filial(ais)"), lRet })
	oNewPag:SetCancelAction({|| .T.}) //FWAlertInfo("Cancelou na pagina 2"), .T.
	oNewPag:SetPrevAction({|| .T.}) //FWAlertInfo("Ops, voce não pode voltar a partir daqui"), .F.
	//oNewPag:SetPrevTitle("Voltar(ou não)")

//--------------------------------------------
// Pagina 3 - Seleção das Tabelas
//--------------------------------------------
	oNewPag := oStepWiz:AddStep("3", {|oPanel| Etapa3(oPanel)})
	oNewPag:SetStepDescription("Seleção das Tabelas")
	oNewPag:SetNextAction({|| FWMsgRun(/*oComponent*/,{ || lRet := ValEtapa3() }, Nil, "Validando seleção de Empresa(s)/Filial(ais)"), lRet })
	oNewPag:SetCancelAction({|| .T.}) //FWAlertInfo("Cancelou na pagina 2"), .T.
	oNewPag:SetPrevAction({|| .T.}) //FWAlertInfo("Ops, voce não pode voltar a partir daqui"), .F.
	//oNewPag:SetPrevTitle("Voltar(ou não)")

//--------------------------------------------
// Pagina 4 - Execução da importação
//--------------------------------------------
	oNewPag := oStepWiz:AddStep("4", {|oPanel| ;
		Etapa4(oPanel, @oStatus), ;
		ExecutaMigracao(oStatus) })
	oNewPag:SetStepDescription("Execução da Migração")
	oNewPag:SetNextAction({|| .T.})
	oNewPag:SetPrevWhen({|| .F. })
	oNewPag:SetCancelWhen({|| .F. })

	oStepWiz:Activate()
	oStepWiz:Destroy()

	RpcClearEnv()
Return

/*/{Protheus.doc} Etapa1
Monta Etapa 1 do Wizard - Boas Vindas

@type function
@author Pablo Nunes
@since 17/07/2023
/*/
Static Function Etapa1(oPanel)
	Local oSay1
	Local oSay2
	Local oSay3
	Local oSay4
	Local oSay5
	Local oSay6
	Local oSay7
	Local cWelcome1 := "Bem vindo(a)!"
	Local cWelcome2 := "Processo de migração dos dados do Posto Inteligente da release 12.1.27 para 12.1.2210."
	Local cWelcome3 := "Ao executar esse programa serão migrados os dados das tabelas selecionadas para as novas tabelas correspondentes."
	Local cWelcome4 := ""
	Local cWelcome5 := "IMPORTANTE: o compartilhamento das tabelas de origem e destino devem ser iguais."
	Local cWelcome6 := "ATENÇÃO: TODOS os registros da tabela de destino serão EXCLUIDOS antes da migração, para a FILIAL escolhida."
	Local cWelcome7 := "Para continuar pressione o botão 'Avançar' ou 'Cancelar' para abortar o processo."

	oCMFont := TFont():New('Arial',,-14,.T.)

	oSay1   := TSay():New(10 , 15, {|| cWelcome1 }, oPanel, , oCMFont, , , , .T., , , 330, 20)
	oSay2   := TSay():New(30 , 15, {|| cWelcome2 }, oPanel, , oCMFont, , , , .T., , , 330, 20)
	oSay3   := TSay():New(50 , 15, {|| cWelcome3 }, oPanel, , oCMFont, , , , .T., , , 330, 20)
	oSay4   := TSay():New(70 , 15, {|| cWelcome4 }, oPanel, , oCMFont, , , , .T., , , 330, 20)
	oSay5   := TSay():New(90 , 15, {|| cWelcome5 }, oPanel, , oCMFont, , , , .T., , , 330, 20)
	oSay6   := TSay():New(110, 15, {|| cWelcome6 }, oPanel, , oCMFont, , , , .T., , , 330, 25)
	oSay7   := TSay():New(145, 15, {|| cWelcome7 }, oPanel, , oCMFont, , , , .T., , , 330, 20)

Return

/*/{Protheus.doc} Etapa2
Monta Etapa 2 do Wizard - Seleção de Filiais

@type function
@author Pablo Nunes
@since 17/07/2023
/*/
Static Function Etapa2(oPanel, aSM0)
	Local oList

	CarregaEmpresas(@aSM0)

	oCMFont := TFont():New('Arial',,-13,.T.)

	// Monta a lista de empresas.
	@ 5, 5 GROUP TO 170, 195 PROMPT "Filiais para Migração" OF oPanel PIXEL
	@ 18, 10 LISTBOX oList;
		FIELDS HEADER "", "Grupo Emp", "Filial", "Descrição" SIZE 180, 148 OF oPanel PIXEL;
		ON DBLCLICK &("StaticCall(UPDR2210, MarcaFilial, oList)")
	oList:SetArray(aEmpresas)
	oList:bLine := {|| { ;
		Iif(aEmpresas[oList:nAt, nMarcado], LoadBitmap(GetResources(),"LBTIK"), LoadBitmap(GetResources(),"LBNO")),;
		aEmpresas[oList:nAt, 2],;
		aEmpresas[oList:nAt, 3],;
		aEmpresas[oList:nAt, 4] }}
	oList:Refresh()

	// Montando Explicação Filiais
	@ 5, 200 GROUP TO 170, 360 PROMPT "ATENÇÃO" COLOR CLR_RED OF oPanel PIXEL
	@ 15, 205 SAY "Selecione a(s) filial(ais) que realizará(ão) a migração dos dados." + CRLF + CRLF +;
		"Obs: recomendamos que esse processo seja feito para cada filial individualmente." + CRLF + CRLF +;
		"" + CRLF +;
		"";
		SIZE 150, 205 OF oPanel PIXEL FONT oCMFont

	oList:SetFocus()

Return

/*/{Protheus.doc} Etapa3
Monta Etapa 2 do Wizard - Seleção de Tabelas

@type function
@author Pablo Nunes
@since 17/07/2023
/*/
Static Function Etapa3(oPanel, aSM0)
	Local oList

	AADD(aTabMigracao, { .F.,  "LF1"        , "MIE"    , "Livro de Movimento de Combustível"      })
	AADD(aTabMigracao, { .F.,  "U65"        , "MHX"    , "Cadastro de Concentradora"              })
	AADD(aTabMigracao, { .F.,  "TQJ"        , "MHY"    , "Cadastro de Bombas de Combustíveis"     })
	AADD(aTabMigracao, { .F.,  "TQI"        , "MHZ"    , "Cadastro de Tanques"                    })
	//AADD(aTabMigracao, { .F.,  "???"        , "MIA"    , "Tabela de Cadastros Genéricos do Posto" })
	//AADD(aTabMigracao, { .F.,  "U00"		, "MIF"	   , "Manutenções e Lacres U00,U01,U02 P/ MIF,MIB"       })
	AADD(aTabMigracao, { .F.,  "DH8"		, "MIB"	   , "Lacres da Bomba"				       })
	AADD(aTabMigracao, { .F.,  "LLI"        , "MIC"    , "Cadastro de Bicos da Bombas"            })
	AADD(aTabMigracao, { .F.,  "LLG"        , "MID"    , "Leitura dos Abastecimentos"             })
	AADD(aTabMigracao, { .F.,  "SL2"        , "SL2"    , "Itens Orçamento"                        })

	oCMFont := TFont():New('Arial',,-13,.T.)

	// Monta a lista de empresas.
	@ 5, 5 GROUP TO 170, 195 PROMPT "Tabelas para Migração" OF oPanel PIXEL
	@ 18, 10 LISTBOX oList;
		FIELDS HEADER "", "Tab. Origem", "Tab. Destino", "Descrição" SIZE 180, 148 OF oPanel PIXEL;
		ON DBLCLICK &("StaticCall(UPDR2210, MarcaTabela, oList)")
	oList:SetArray(aTabMigracao)
	oList:bLine := {|| { ;
		Iif(aTabMigracao[oList:nAt, nMarcado], LoadBitmap(GetResources(),"LBTIK"), LoadBitmap(GetResources(),"LBNO")),;
		aTabMigracao[oList:nAt, 2],;
		aTabMigracao[oList:nAt, 3],;
		aTabMigracao[oList:nAt, 4] }}
	oList:Refresh()

	// Montando Explicação Filiais
	@ 5, 200 GROUP TO 170, 360 PROMPT "ATENÇÃO" COLOR CLR_RED OF oPanel PIXEL
	@ 15, 205 SAY "Selecione a(s) tabela(s) que realizará(ão) a migração dos dados." + CRLF + CRLF +;
		"Obs: esse processo poderá ser feito para cada tabela individualmente." + CRLF + CRLF +;
		"" + CRLF +;
		"";
		SIZE 150, 205 OF oPanel PIXEL FONT oCMFont

	oList:SetFocus()

Return

/*/{Protheus.doc} Etapa4
Monta Etapa 4 do Wizard - Acompanhamento e Execução

@type Function
@author Pablo Nunes
@since 31/07/2023
@param 01 - oPanel , objeto, painel para exibição da etapa
@param 02 - oStatus, objeto, objeto LISTBOX utilizado para apresentar os dados da execução
/*/
Static Function Etapa4(oPanel, oStatus)
	Local aStatus := {}
	Local cStatus
	Local oBtnPanel := TPanel():New(0, 0, "", oPanel, , , , , , 40, 40, .T., .T.)
	Local oFont

	//Tela de parametros
	xPergunte()
	oBtnPanel:Align := CONTROL_ALIGN_ALLCLIENT

	DEFINE FONT oFont NAME "Courier New" SIZE 10, 0
	@ 5, 5 LISTBOX oStatus VAR cStatus ITEMS aStatus SIZE 355, 160 OF oBtnPanel PIXEL  FONT oFont

Return

/*/{Protheus.doc} CarregaEmpresas
Cria Array aEmpresas Carregando as Empresas

@type function
@author Pablo Nunes
@since 17/07/2023
/*/
Static Function CarregaEmpresas(aSM0)
	Local aGrupo    := {}
	Local cGrpFil   := ""
	Local cLayout   := ""
	Local nEmpresa
	Local nLayout
	Local nSM0
	Local oTamanhos := JsonObject():New()

	SET DELET ON

	OpenSM0()
	aGrupo := FWAllGrpCompany()
	For nEmpresa := 1 To Len(aGrupo)
		cLayout := FWSM0Layout(aGrupo[nEmpresa])
		oTamanhos[aGrupo[nEmpresa]] := JsonObject():New()
		oTamanhos[aGrupo[nEmpresa]]['nTamEmp']  := 0
		oTamanhos[aGrupo[nEmpresa]]['nTamUnid'] := 0
		oTamanhos[aGrupo[nEmpresa]]['nTamFil']  := 0
		For nLayout := 1 To Len(cLayout)
			If SubStr(cLayout,nLayout,1) == "E"
				oTamanhos[aGrupo[nEmpresa]]['nTamEmp']  += 1
			ElseIf SubStr(cLayout,nLayout,1) == "U"
				oTamanhos[aGrupo[nEmpresa]]['nTamUnid'] += 1
			ElseIf SubStr(cLayout,nLayout,1) == "F"
				oTamanhos[aGrupo[nEmpresa]]['nTamFil']  += 1
			EndIf
		Next nLayout
	Next aGrupo

	aSM0 := FWLoadSM0()
	aEmpresas := {}
	For nSM0 := 1 To Len(aSM0)
		cGrpFil := PadR(aSM0[nSM0][3], oTamanhos[aSM0[nSM0][1]]['nTamEmp'])  +;
			PadR(aSM0[nSM0][4], oTamanhos[aSM0[nSM0][1]]['nTamUnid']) +;
			PadR(aSM0[nSM0][5], oTamanhos[aSM0[nSM0][1]]['nTamFil'])

		AADD(aEmpresas, { .F., AllTrim(aSM0[nSM0][1]), cGrpFil, AllTrim(aSM0[nSM0][7]) })
	Next nSM0

	For nEmpresa := 1 To Len(aGrupo)
		FreeObj(oTamanhos[aGrupo[nEmpresa]])
		oTamanhos[aGrupo[nEmpresa]] := Nil
	Next aGrupo

	FreeObj(oTamanhos)
	oTamanhos := Nil

	FwFreeArray(aGrupo)

Return

/*/{Protheus.doc} MarcaFilial
Marca a Filial da Linha

@type function
@author Pablo Nunes
@since 17/07/2023
/*/
Static Function MarcaFilial(oList)
	aEmpresas[oList:nAt, nMarcado] := !aEmpresas[oList:nAt, nMarcado]
	oList:Refresh(.F.)
Return

/*/{Protheus.doc} ValEtapa2
Validação do botão Próximo da página 2

@type function
@author Pablo Nunes
@since 17/07/2023
/*/
Static Function ValEtapa2()
	Local lValid := .T.
	Local nPosEmp := 0
	If !(lValid := ValSelEmpresa())
		FWAlertInfo("Selecione ao menos uma empresa", "Atenção")
	EndIf

	if lValid
		nPosEmp := aScan(aEmpresas, {|x| x[nMarcado] == .T. })
		//faço login na primeira empresa
		RPCSetType(3)  // Nao consumir licenca
		RpcClearEnv()
		if lValid := RPCSETENV(aEmpresas[nPosEmp][2], aEmpresas[nPosEmp][3]) //conecta na empresa	
			cEmpAnt		:= aEmpresas[nPosEmp][2]
			cFilant		:= aEmpresas[nPosEmp][3]
		else
			FWAlertInfo("Não foi possivel conectar empresa e filial!", "Atenção")
		endif
	endif
Return lValid

Static Function ValSelEmpresa()
Return (aScan(aEmpresas, {|x| x[nMarcado] == .T. }) > 0)

/*/{Protheus.doc} MarcaTabela
Marca a Tabela da Linha

@type function
@author Pablo Nunes
@since 17/07/2023
/*/
Static Function MarcaTabela(oList)
	aTabMigracao[oList:nAt, nMarcado] := !aTabMigracao[oList:nAt, nMarcado]
	oList:Refresh(.F.)
Return

/*/{Protheus.doc} ValEtapa3
Validação do botão Próximo da página 3

@type function
@author Pablo Nunes
@since 17/07/2023
/*/
Static Function ValEtapa3()
	Local lValid := .T.
	If !(lValid := ValSelTabela())
		FWAlertInfo("Selecione ao menos uma tabela", "Atenção")
	EndIf
Return lValid

Static Function ValSelTabela()
Return (aScan(aTabMigracao, {|x| x[nMarcado] == .T. }) > 0)

/*/{Protheus.doc} ExecutaMigracao
Executa os Procedimentos de Migração

@type Function
@author Pablo Nunes
@since 31/07/2023

@param 01 - oStatus, objeto, objeto LISTBOX utilizado para apresentar os dados da execução
/*/
Static Function ExecutaMigracao(oStatus)
	Local nX := 1, nY := 1
	Local cEmpBkp := cEmpAnt, cFilBkp := cFilAnt
	Local aDePara := {}

	oStatus:Refresh()

	For nX:=1 to Len(aEmpresas)

		If aEmpresas[nX,nMarcado]

			oStatus:Add(Padr(Dtoc(MsDate()), 14) + Padr(Time(), 10) + ' - ' + "Conectando Ambiente" + ' - ' + aEmpresas[nX][2] + '/' + aEmpresas[nX][3])
			oStatus:Refresh()
			AbreAmbiente(aEmpresas[nX][2], aEmpresas[nX][3])

			For nY:=1 to Len(aTabMigracao)

				If aTabMigracao[nY,nMarcado]

					aDePara := fRetDePara(aTabMigracao[nY,2])

					//filtros da tabela
					cWhere := " AND "+IIF(SubStr(aTabMigracao[nY,2],1,1) == "S",SubStr(aTabMigracao[nY,2],2,2),aTabMigracao[nY,2])+"_FILIAL = '"+xFilial(aTabMigracao[nY,2])+"'"
					
					cDescTab := aTabMigracao[nY,4]
					DbSelectArea(aTabMigracao[nY,2])
					DbSelectArea(aTabMigracao[nY,3])
					if fMigraDados(oStatus,aTabMigracao[nY,2],aTabMigracao[nY,3],aDePara,cWhere,cDescTab)
						oStatus:Add(Padr(Dtoc(MsDate()), 14) + Padr(Time(), 10) + ' - ' + "Migração de "+cDescTab+" concluída com sucesso.")
					else
						oStatus:Add(Padr(Dtoc(MsDate()), 14) + Padr(Time(), 10) + ' - ' + "Migração de "+cDescTab+" concluida com FALHAS.")
					endif
					oStatus:Refresh()

				EndIf

			Next nY

			// Fecha ambiente
			oStatus:Add(Padr(Dtoc(MsDate()), 14) + Padr(Time(), 10) + ' - ' + "Ambiente Encerrado" + ' - ' + aEmpresas[nX][2] + '/' +  aEmpresas[nX][3])
			oStatus:Refresh()
			AbreAmbiente(cEmpBkp, cFilBkp)

		EndIf
	Next nX

	oStatus:Add(Padr(Dtoc(MsDate()), 14) + Padr(Time(), 10) + ' - ' + "Migrações Finalizadas")
	oStatus:Refresh()

Return

Static Function AbreAmbiente(cCompany, cBranch)
	Local lRet := .T.
	cEmpAnt := cCompany
	cFilAnt := cBranch
	FWSM0Util():setSM0PositionBycFilAnt()
Return lRet

/*/{Protheus.doc} fMigraDados
Função de migração de campos da tabela origem para a tabela destino

@type function
@author Pablo Nunes
@since 31/07/2023
@param cAOrig, character, alias da tabela de origem
@param cADest, character, alias da tabela de destino
@param aDePara, array, relação de campos De/Para
@param cWhere, character, filtro na consulta dos dados de origem
/*/
Static Function fMigraDados(oStatus,cAOrig,cADest,aDePara,cWhere,cDescTab)
	Local aArea	:= GetArea()
	Local aAreaOrig	:= (cAOrig)->( GetArea() )
	Local aAraaDest := (cADest)->( GetArea() )
	Local cCampDest :=  ""
	Local cCampOrig :=  ""

	Local cQry := ""
	Local nX := 0

	Local nAtual := 0
	Local nTotReg := 0
	Local cPercentual := ""
	Local nPosReg := 0
	Local cTexto := ""
	Local _lInclui := .F.
	Local cCpoFil := ""

	If cAOrig <> "SL2"
		// deleto registros da tabela de destino, na filial que esta sendo processada a migração
		cQry := "DELETE FROM " + RetSQLName(cADest) + " " + CRLF
		cQry += " WHERE 1 = 1 " + CRLF
		cQry += " AND "+IIF(SubStr(cADest,1,1) == "S",SubStr(cADest,2,2),cADest)+"_FILIAL = '"+xFilial(cADest)+"' " + CRLF
		if cADest == "MID" //abastecimentos
			cQry += "AND LEFT(MID_CODABA, 3) = 'LLG' "
		endif

		If TCSqlExec(cQry) < 0
			FWAlertInfo(TCSqlError(),"ERRO")
			Return .F.
		EndIf
		_lInclui := .T.

		/*
		If cAOrig == "U00"
			cQry := "DELETE FROM " + RetSQLName("MIB") + " " + CRLF
			cQry += " WHERE 1 = 1 " + CRLF
			cQry += " AND MIB_FILIAL = '"+xFilial("MIB")+"' " + CRLF

			If TCSqlExec(cQry) < 0
				FWAlertInfo(TCSqlError(),"ERRO")
				Return .F.
			EndIf
		
		EndIf*/

		if cAOrig == "TQJ"
			cQry := "DELETE FROM " + RetSQLName("MIA") + " " + CRLF
			cQry += " WHERE MIA_TIPO = '03' " + CRLF
			cQry += " AND MIA_FILIAL = '"+xFilial("MIA")+"' " + CRLF

			If TCSqlExec(cQry) < 0
				FWAlertInfo(TCSqlError(),"ERRO")
				Return .F.
			EndIf
		endif

		if cADest == "MID"

			// Carga inicial de migração da tabela
			oStatus:Add(Padr(Dtoc(MsDate()), 14) + Padr(Time(), 10) + ' - ' + "Migrando via UPDATE tabela " + cDescTab)

			if empty(MV_PAR01)
				// Carga inicial de migração da tabela
				oStatus:Add(Padr(Dtoc(MsDate()), 14) + Padr(Time(), 10) + ' - ' + " INFORME UMA DATA DE CORTE " + cDescTab)
				Return .F.
			endif
			
			cWhere := " WHERE LLG.D_E_L_E_T_ = ' '"
			cWhere += " AND LLG_FILIAL = '"+xFilial("LLG")+"'"
			cWhere += " AND LLG_DATACO >= '"+DtoS(MV_PAR01)+"' "

			//BUSCO A QUANTIDADE DE REGISTROS
			cQry := "SELECT COUNT(*) QTDREG"  + CRLF
			cQry += " FROM " + RetSQLName("LLG") + " LLG " + CRLF
			cQry += cWhere

			If Select("QAUX") > 0
				QAUX->(DbCloseArea())
			EndIf

			cQry := ChangeQuery(cQry)
			TcQuery cQry New ALIAS "QAUX"

			nTotReg := QAUX->QTDREG

			oStatus:Add(Padr(Dtoc(MsDate()), 14) + Padr(Time(), 10) + ' - ' + "Quantidade total de registros encontrados: " + cValToChar(nTotReg) )

			QAUX->(DbCloseArea())

			//BUSCO ULTIMO RECNO DA TABELA DESTINO
			cQry := "SELECT MAX(R_E_C_N_O_) MAXREC"  + CRLF
			cQry += " FROM " + RetSQLName("MID") + " MID " + CRLF

			If Select("QAUX") > 0
				QAUX->(DbCloseArea())
			EndIf

			cQry := ChangeQuery(cQry)
			TcQuery cQry New ALIAS "QAUX"

			nTotReg := QAUX->MAXREC
			QAUX->(DbCloseArea())

			// faço a busca dos campos da tabela de origem
			cCampOrig := ""
			cCampDest := ""
			For nX := 1 to Len(aDePara)
				if aDePara[nX][2] == "MID_CODABA"
					cCampOrig += "'LLG00'+"+aDePara[nX][1] + ", "
				else
					cCampOrig += aDePara[nX][1] + ", "
				endif
				cCampDest += aDePara[nX][2] + ", "

				if aDePara[nX][2] == "MID_NUMORC" //adiciono afericao
					cCampOrig += "(CASE WHEN LLG.LLG_NUM='0' THEN 'S' ELSE ' ' END)" +", "
					cCampDest += "MID_AFERIR, "
				endif
			Next nX
			cCampOrig += "(ROW_NUMBER() OVER(ORDER BY R_E_C_N_O_)+"+cValToChar(nTotReg)+"), 0"
			cCampDest += "R_E_C_N_O_, R_E_C_D_E_L_"

			cQry := "INSERT INTO " + RetSQLName("MID") 
			cQry += " ("+cCampDest+")"
			cQry += " SELECT "+cCampOrig
			cQry += " FROM " + RetSQLName("LLG") + " LLG "
			cQry += cWhere

			If TCSqlExec(cQry) < 0
				FWAlertInfo(TCSqlError(),"ERRO")
				Return .F.
			EndIf

			Return .T.
		endif

	Else

		oStatus:Add(Padr(Dtoc(MsDate()), 14) + Padr(Time(), 10) + ' - ' + "Migrando via UPDATE tabela " + cDescTab)
		
		if empty(MV_PAR01)
			// Carga inicial de migração da tabela
			oStatus:Add(Padr(Dtoc(MsDate()), 14) + Padr(Time(), 10) + ' - ' + " INFORME UMA DATA DE CORTE " + cDescTab)
			Return .F.
		endif

		cWhere := " WHERE D_E_L_E_T_ = ' ' " + CRLF
		cWhere += " AND "+IIF(SubStr(cAOrig,1,1) == "S",SubStr(cAOrig,2,2),cAOrig)+"_FILIAL = '"+xFilial(cAOrig)+"' " + CRLF
		cWhere += " AND L2_LEGCOD <> ' ' "
		cWhere += " AND L2_EMISSAO >= '"+DtoS(MV_PAR01)+"' "

		cQry := "SELECT COUNT(*) QTDREG"  + CRLF
		cQry += " FROM " + RetSQLName(cAOrig) + " " + cAOrig + " " + CRLF
		cQry += cWhere

		If Select("QAUX") > 0
			QAUX->(DbCloseArea())
		EndIf

		cQry := ChangeQuery(cQry)
		TcQuery cQry New ALIAS "QAUX"

		nTotReg := QAUX->QTDREG

		// Carga inicial de migração da tabela
		oStatus:Add(Padr(Dtoc(MsDate()), 14) + Padr(Time(), 10) + ' - ' + "Quantidade total de registros encontrados: " + cValToChar(nTotReg) )

		QAUX->(DbCloseArea())

		if nTotReg > 0
			cQry := "UPDATE " + RetSQLName(cAOrig) + " " + CRLF
			cQry += " SET L2_MIDCOD = 'LLG00'+L2_LEGCOD " + CRLF
			if SL2->(Fieldpos("L2_BICO")) > 0
				cQry += ", L2_MICCOD = L2_BICO " + CRLF
			Endif
			cQry += cWhere
			
			If TCSqlExec(cQry) < 0
				FWAlertInfo(TCSqlError(),"ERRO")
				oStatus:Add(Padr(Dtoc(MsDate()), 14) + Padr(Time(), 10) + ' - ' + "Falha na execução do Update! ")
				Return .F.
			else
				oStatus:Add(Padr(Dtoc(MsDate()), 14) + Padr(Time(), 10) + ' - ' + "Update executado com sucesso! ")
			EndIf
		endif

		RestArea( aAraaDest )
		RestArea( aAreaOrig )
		RestArea( aArea )

		Return .T.
	EndIf

	// faço a busca dos registros da tabela de origem
	cCampOrig :=  ""
	For nX := 1 to Len(aDePara)
		if !(aDePara[nX][1] $ cCampOrig) .AND. aDePara[nX][1]<>"RELACAO"
			cCampOrig += aDePara[nX][1] + ", "
		endif
		If len(aDePara[nX])>2 .AND. aDePara[nX][1]<>"RELACAO" .AND. !Empty(aDePara[nX][3])
			cCpoFil := aDePara[nX][3]
		Endif
	Next nX
	cCampOrig := SubStr(cCampOrig,1,Len(cCampOrig)-2) //remove a vigula do ultimo campo adicionado a string

	cQry := "SELECT " + cCampOrig + CRLF
	cQry += " FROM " + RetSQLName(cAOrig) + " " + cAOrig + " " + CRLF
	/*IF cAOrig == "U00"
		cQry += " INNER JOIN "+ RetSQLName("U01") + " U01 " + CRLF
		cQry += " 	ON U01.U01_FILIAL = U00.U00_FILIAL AND U01.U01_NUMSEC = U00.U00_NUMSEC AND U01.D_E_L_E_T_ = U00.D_E_L_E_T_ "+ CRLF
		cQry += " INNER JOIN "+ RetSQLName("U02") + " U02 " + CRLF
		cQry += " 	ON U02.U02_FILIAL = U00.U00_FILIAL AND U02.U02_NUMSEC = U00.U00_NUMSEC AND U02.D_E_L_E_T_ = U00.D_E_L_E_T_ "+ CRLF
	EndIf*/
	cQry += " WHERE " + cAOrig + ".D_E_L_E_T_ = ' ' " + CRLF
	If !Empty(MV_PAR01) .and. !Empty(cCpoFil)
		cQry += " AND "+ cAOrig+"."+cCpoFil +" >= '"+DtoS(MV_PAR01)+"' "
	EndIf
	cQry += cWhere

	If Select("QAUX") > 0
		QAUX->(DbCloseArea())
	EndIf

	cQry := ChangeQuery(cQry)
	TcQuery cQry New ALIAS "QAUX"

	QAUX->(DbGoTop())
	If QAUX->(!Eof())
		QAUX->(dbEval({|| nTotReg++})) //quantidade de registros
	EndIf

	QAUX->(DbGoTop())

	// Carga inicial de migração da tabela
	oStatus:Add(Padr(Dtoc(MsDate()), 14) + Padr(Time(), 10) + ' - ' + "Migrando " + cDescTab)
	oStatus:Add(Padr(Dtoc(MsDate()), 14) + Padr(Time(), 10) + ' - ' + cValToChar(0) + " " + cDescTab + " Enviados"+ " (  0%)")
	oStatus:Refresh()
	nPosReg := oStatus:Len()

	If QAUX->(!EOF())
		While QAUX->(!EOF())
			
			If cADest == "SL2"
				SL2->(DbGoto(QAUX->R_E_C_N_O_))
			EndIf

			nAtual++
			cPercentual = " (" + cValToChar(Round(nAtual / nTotReg * 100, 0)) + "%)"

			cTexto := Padr(Dtoc(MsDate()), 14) + Padr(Time(), 10) + ' - ' + cValToChar(nAtual) + " de " + cValToChar(nTotReg) + " " + cDescTab + " Enviados" + cPercentual
			oStatus:Modify(cTexto, nPosReg)
			oStatus:Refresh()

			RecLock(cADest,_lInclui)
			/*If cADest == "MIF"
				RecLock("MIB",_lInclui)
			EndIf*/

			For nX := 1 to Len(aDePara)
				If aDePara[nX][2] == "R_E_C_N_O_" .or. aDePara[nX][2] == "L2_EMISSAO"
					Loop
				//ElseIf SubStr(aDePara[nX][2],1,3) == "MIB"
					//cADest := "MIB"
				Endif

				if aDePara[nX][1] == "RELACAO"
					if cADest == "MHY" .AND. aDePara[nX][2] == "MHY_ENSPED"
						if QAUX->TQJ_BOMBA $ SuperGetMv("MV_XBOMBAR",,"")
							MHY->MHY_ENSPED := "2" //não
						else
							MHY->MHY_ENSPED := "1" //sim
						endif
					else
						(cADest)->&(aDePara[nX][2]) := aDePara[nX][3]
					endif
					Loop
				endif

				If GetSx3Cache(aDePara[nX][2],"X3_TIPO") == "D"
					(cADest)->&(aDePara[nX][2])	:= StoD(QAUX->&(aDePara[nX][1]))
				Else
					If cADest == "MHX" .and. aDePara[nX][2] == "MHX_CODFAB"
						(cADest)->&(aDePara[nX][2])	:= "0"+QAUX->&(aDePara[nX][1])
					ElseIf cADest == "MHX" .and.  aDePara[nX][2] == "MHX_PORTA"
						(cADest)->&(aDePara[nX][2])	:= Val(QAUX->&(aDePara[nX][1]))
					ElseIf cADest == "MHZ" .and.  aDePara[nX][2] == "MHZ_CODPRO"
						(cADest)->&(aDePara[nX][2])	:= QAUX->&(aDePara[nX][1])
						MHZ->MHZ_DESPRO := Posicione("SB1",1,xFilial("SB1")+QAUX->&(aDePara[nX][1]),"B1_DESC") // Foi feito pq o campo de origem é virtual
						MHZ->MHZ_CODANP := IIF(SB1->(FieldPos("B1_CODSIMP")) > 0,SB1->B1_CODSIMP,"")
						If SB5->(FieldPos("B5_CODANP")) > 0 .and. Empty(MHZ->MHZ_CODANP)
							MHZ->MHZ_CODANP := Posicione("SB5",1,xFilial("SB5")+QAUX->&(aDePara[nX][1]),"B5_CODANP")
						EndIf
						if !empty(MHZ->MHZ_CODANP)
							MHZ->MHZ_DESANP := Posicione("SZO",1,xFilial("SZO")+MHZ->MHZ_CODANP,"ZO_DESCRI")
						endif
					ElseIf cADest == "MHY" .and. aDePara[nX][2] == "MHY_FABBOM"
						cCodFab := StrZero(Val(QAUX->TQJ_FABRIC),3)
						cFabric	:= Alltrim(Posicione("MIA",1,xFilial("MIA")+cCodFab+'03',"MIA_DESCRI"))
						if empty(cFabric)
							RecLock("MIA", .T.)
								MIA->MIA_FILIAL := xFilial("MIA")
								MIA->MIA_CODIGO := cCodFab
								MIA->MIA_TIPO	:= "03" //fabricande de bombas
								MIA->MIA_DESCRI := QAUX->TQJ_FABBOM
							MIA->(MsUnlock())
						endif
						MHY->MHY_FABBOM := cCodFab
					ElseIf cADest == "MID" .and. aDePara[nX][2] == "MID_CODABA"
						(cADest)->&(aDePara[nX][2])	:= "LLG00"+QAUX->&(aDePara[nX][1])
					ElseIf cADest == "MID" .and. aDePara[nX][2] == "MID_NUMORC"
						(cADest)->&(aDePara[nX][2])	:= QAUX->&(aDePara[nX][1])
						if Alltrim(QAUX->&(aDePara[nX][1])) == "0" //afericao
							MID->MID_AFERIR := "S"
						endif
					ElseIf cADest == "SL2" .and. aDePara[nX][2] == "L2_MIDCOD"
						(cADest)->&(aDePara[nX][2])	:= "LLG00"+QAUX->&(aDePara[nX][1])
					Else
						(cADest)->&(aDePara[nX][2])	:= QAUX->&(aDePara[nX][1])
					EndIf

				EndIf

				/*If SubStr(aDePara[nX][2],1,3) == "MIB"
					cADest := "MIF"
				Endif*/
			Next nX
			(cADest)->(MsUnLock())
			/*If cADest == "MIF"
				MIB->(MsUnLock())
			EndIf*/
			QAUX->(DbSkip())
		EndDo
	Else
		Help(,, "Atenção",, "Não há dados na tabela " + cDescTab + " a serem importados!", 1, 0)
	EndIf

	QAUX->(DbCloseArea())

	RestArea( aAraaDest )
	RestArea( aAreaOrig )
	RestArea( aArea )

Return .T.

Static Function fRetDePara(cAlias)
	Local aDePara := {}

	If cAlias == "LF1" //AADD(aTabMigracao, { .F.,  "LF1"        , "MIE"    , "Livro de Movimento de Combustível"      })
		aDePara := {}
		aadd(aDePara,{"LF1_FILIAL","MIE_FILIAL"	,})
		aadd(aDePara,{"LF1_DATA"  ,"MIE_DATA"	,"LF1_DATA"})
		aadd(aDePara,{"LF1_PRODUT","MIE_CODPRO"	,})
		aadd(aDePara,{"LF1_TANQUE","MIE_CODTAN"	,})
		aadd(aDePara,{"LF1_NRLIVR","MIE_NRLIVR"	,})
		//aadd(aDePara,{"        ","MIE_NROPAG"	,})
		aadd(aDePara,{"LF1_OBS	 ","MIE_OBS	  "	,})
		aadd(aDePara,{"LF1_BICO	 ","MIE_CODBIC"	,})
		aadd(aDePara,{"LF1_ABERT ","MIE_ABERT"	,})
		aadd(aDePara,{"LF1_VENDAS","MIE_VENDAS"	,})
		aadd(aDePara,{"LF1_VLRITE","MIE_VLRITE"	,})
		aadd(aDePara,{"LF1_ESTESC","MIE_ESTESC"	,})
		aadd(aDePara,{"LF1_ESTFEC","MIE_ESTFEC"	,})
		aadd(aDePara,{"LF1_VOLDIS","MIE_VOLDIS"	,})
		aadd(aDePara,{"LF1_AFERIC","MIE_AFERIC"	,})
		aadd(aDePara,{"LF1_PERDA ","MIE_PERDA "	,})
		aadd(aDePara,{"LF1_GANHOS","MIE_GANHOS"	,})
		aadd(aDePara,{"LF1_ENCINI","MIE_ENCINI"	,})
		aadd(aDePara,{"LF1_ENCFIN","MIE_ENCFIN"	,})
		aadd(aDePara,{"LF1_ENTRAD","MIE_ENTRAD"	,})
		aadd(aDePara,{"LF1_NOTA	 ","MIE_NOTA  "	,})
		aadd(aDePara,{"LF1_NOTA02","MIE_NOTA02"	,})
		aadd(aDePara,{"LF1_NOTA03","MIE_NOTA03"	,})
		aadd(aDePara,{"LF1_NOTA04","MIE_NOTA04"	,})
		aadd(aDePara,{"LF1_NOTA05","MIE_NOTA05"	,})
		aadd(aDePara,{"LF1_TANQUD","MIE_TANQUD"	,})
		aadd(aDePara,{"LF1_ACUMUL","MIE_ACUMUL"	,})
		aadd(aDePara,{"LF1_ESTI01","MIE_ESTI01"	,})
		aadd(aDePara,{"LF1_ESTI02","MIE_ESTI02"	,})
		aadd(aDePara,{"LF1_ESTI03","MIE_ESTI03"	,})
		aadd(aDePara,{"LF1_ESTI04","MIE_ESTI04"	,})
		aadd(aDePara,{"LF1_ESTI05","MIE_ESTI05"	,})
		aadd(aDePara,{"LF1_ESTI06","MIE_ESTI06"	,})
		aadd(aDePara,{"LF1_ESTI07","MIE_ESTI07"	,})
		aadd(aDePara,{"LF1_ESTI08","MIE_ESTI08"	,})
		aadd(aDePara,{"LF1_ESTI09","MIE_ESTI09"	,})
		aadd(aDePara,{"LF1_ESTI10","MIE_ESTI10"	,})
		aadd(aDePara,{"LF1_ESTI11","MIE_ESTI11"	,})
		aadd(aDePara,{"LF1_ESTI12","MIE_ESTI12"	,})
		aadd(aDePara,{"LF1_ESTI13","MIE_ESTI13"	,})
		aadd(aDePara,{"LF1_ESTI14","MIE_ESTI14"	,})
		aadd(aDePara,{"LF1_ESTI15","MIE_ESTI15"	,})
		aadd(aDePara,{"LF1_ESTI16","MIE_ESTI16"	,})
		aadd(aDePara,{"LF1_ESTI17","MIE_ESTI17"	,})
		aadd(aDePara,{"LF1_ESTI18","MIE_ESTI18"	,})
		aadd(aDePara,{"LF1_ESTI19","MIE_ESTI19"	,})
		aadd(aDePara,{"LF1_ESTI20","MIE_ESTI20"	,})
		aadd(aDePara,{"LF1_VTAQ01","MIE_VTAQ01"	,})
		aadd(aDePara,{"LF1_VTAQ02","MIE_VTAQ02"	,})
		aadd(aDePara,{"LF1_VTAQ03","MIE_VTAQ03"	,})
		aadd(aDePara,{"LF1_VTAQ04","MIE_VTAQ04"	,})
		aadd(aDePara,{"LF1_VTAQ05","MIE_VTAQ05"	,})
		aadd(aDePara,{"LF1_VTAQ06","MIE_VTAQ06"	,})
		aadd(aDePara,{"LF1_VTAQ07","MIE_VTAQ07"	,})
		aadd(aDePara,{"LF1_VTAQ08","MIE_VTAQ08"	,})
		aadd(aDePara,{"LF1_VTAQ09","MIE_VTAQ09"	,})
		aadd(aDePara,{"LF1_VTAQ10","MIE_VTAQ10"	,})
		aadd(aDePara,{"LF1_VTAQ11","MIE_VTAQ11"	,})
		aadd(aDePara,{"LF1_VTAQ12","MIE_VTAQ12"	,})
		aadd(aDePara,{"LF1_VTAQ13","MIE_VTAQ13"	,})
		aadd(aDePara,{"LF1_VTAQ14","MIE_VTAQ14"	,})
		aadd(aDePara,{"LF1_VTAQ15","MIE_VTAQ15"	,})
		aadd(aDePara,{"LF1_VTAQ16","MIE_VTAQ16"	,})
		aadd(aDePara,{"LF1_VTAQ17","MIE_VTAQ17"	,})
		aadd(aDePara,{"LF1_VTAQ18","MIE_VTAQ18"	,})
		aadd(aDePara,{"LF1_VTAQ19","MIE_VTAQ19"	,})
		aadd(aDePara,{"LF1_VTAQ20","MIE_VTAQ20"	,})
		aadd(aDePara,{"LF1_PERCGP","MIE_XPERGP"	,})
		if LF1->(Fieldpos("LF1_KARDEX")) > 0
			aadd(aDePara,{"LF1_KARDEX","MIE_XKARDE"	,})
		Endif
	
	ElseIf cAlias == "U65" //AADD(aTabMigracao, { .F.,  "U65"        , "MHX"    , "Cadastro de Concentradora"              })
		aadd(aDePara,{"U65_FILIAL","MHX_FILIAL"	,})
		aadd(aDePara,{"U65_CODIGO","MHX_CODCON"	,})
		aadd(aDePara,{"U65_FABRIC","MHX_CODFAB"	,})
		aadd(aDePara,{"U65_IP","MHX_IP"			,})
		aadd(aDePara,{"U65_PORTA","MHX_PORTA"	,})
		aadd(aDePara,{"U65_STATUS","MHX_STATUS"	,})
		aadd(aDePara,{"U65_MODELO","MHX_MODELO"	,})
		aadd(aDePara,{"U65_MODELO","MHX_DESC"	,})
		aadd(aDePara,{"U65_LEITUR","MHX_XLEITU"	,})
		aadd(aDePara,{"RELACAO","MHX_DECTOT"	, 2 })
		aadd(aDePara,{"RELACAO","MHX_DECPRC"	, 3 })
		aadd(aDePara,{"RELACAO","MHX_DECVOL"	, 3 })
		aadd(aDePara,{"RELACAO","MHX_CASAMI"	, 1 })

	ElseIf cAlias == "TQJ" //AADD(aTabMigracao, { .F.,  "TQJ"        , "MHY"    , "Cadastro de Bombas de Combustíveis"     })
		aadd(aDePara,{"TQJ_FILIAL","MHY_FILIAL"	,})
		aadd(aDePara,{"TQJ_BOMBA","MHY_CODBOM"	,})
		aadd(aDePara,{"TQJ_CONCEN","MHY_CODCON"	,})
		aadd(aDePara,{"TQJ_FABRIC","R_E_C_N_O_"	,})
		aadd(aDePara,{"TQJ_FABBOM","MHY_FABBOM"	,})
		aadd(aDePara,{"TQJ_MODELO","MHY_MODBOM"	,})
		aadd(aDePara,{"TQJ_SERIE","MHY_SERIE"	,})
		aadd(aDePara,{"TQJ_TIPMED","MHY_TIPMED"	,})
		aadd(aDePara,{"TQJ_DIAMBO","MHY_DIAMBO"	,})
		aadd(aDePara,{"TQJ_DTCONT","MHY_DTCONT"	,})
		aadd(aDePara,{"TQJ_HRCONT","MHY_HRCONT"	,})
		aadd(aDePara,{"TQJ_CONINI","MHY_CONINI"	,})
		aadd(aDePara,{"TQJ_MOTIVO","MHY_MOTIVO"	,})
		aadd(aDePara,{"TQJ_LIMCON","MHY_LIMCON"	,})
		aadd(aDePara,{"TQJ_LADO1","MHY_LADO1"	,})
		aadd(aDePara,{"TQJ_LADO2","MHY_LADO2"	,})
		aadd(aDePara,{"TQJ_STATUS","MHY_STATUS"	,})
		aadd(aDePara,{"RELACAO","MHY_ENSPED"	,"1"})

	ElseIf cAlias == "TQI" //AADD(aTabMigracao, { .F.,  "TQI"        , "MHZ"    , "Cadastro de Tanques"                    })
		aadd(aDePara,{"TQI_FILIAL","MHZ_FILIAL"	,})
		aadd(aDePara,{"TQI_PRODUT","MHZ_CODPRO"	,})
		aadd(aDePara,{"TQI_TANQUE","MHZ_CODTAN"	,})
		aadd(aDePara,{"TQI_TANQUE","MHZ_LOCAL"	,})
		//aadd(aDePara,{"TQI_DESPRO","MHZ_DESPRO",})
		aadd(aDePara,{"TQI_CAPNOM","MHZ_CAPNOM"	,})
		aadd(aDePara,{"TQI_CAPMAX","MHZ_CAPMAX"	,})
		aadd(aDePara,{"TQI_INSTAL","MHZ_INSTAL"	,})
		aadd(aDePara,{"TQI_DIAMET","MHZ_DIAMET"	,})
		aadd(aDePara,{"TQI_INCLIN","MHZ_INCLIN"	,})
		aadd(aDePara,{"TQI_DTATIV","MHZ_DTATIV"	,})
		aadd(aDePara,{"TQI_DTDESA","MHZ_DTDESA"	,})
		aadd(aDePara,{"TQI_TQSPED","MHZ_TQSPED"	,})
		aadd(aDePara,{"TQI_STATUS","MHZ_STATUS"	,})
		aadd(aDePara,{"TQI_DESCR","MHZ_XDESCR"	,})
		aadd(aDePara,{"RELACAO","MHZ_INSTAL"	,"2"})


	//ElseIf cAlias == "???" ////AADD(aTabMigracao, { .F.,  "???"        , "MIA"    , "Tabela de Cadastros Genéricos do Posto" })
	/*ElseIf cAlias == "U00" //AADD(aTabMigracao, { .F.,  "U00/U01/DH8", "MIB/MIF", "Manutenções e Lacres"                   })
		aadd(aDePara,{"U00_FILIAL","MIF_FILIAL"	,})
		aadd(aDePara,{"U00_NUMSEQ","MIF_CODMAN"	,})
		aadd(aDePara,{"U00_NUMINT","MIF_NUMINT"	,})
		aadd(aDePara,{"U00_DTINT","MIF_DTSUB"	,})
		aadd(aDePara,{"U00_HORAIN","MIF_HRSUB"	,})
		aadd(aDePara,{"U00_MOTINT","MIF_MOTIVO"	,})
		aadd(aDePara,{"U00_CNPJFO","MIF_CNPJEM"	,})
		aadd(aDePara,{"U00_CPFTEC","MIF_CPFTEC"	,})
		aadd(aDePara,{"U00_NUMTEC","MIF_NOMTEC"	,})
		aadd(aDePara,{"U01_FILIAL","MIB_FILIAL"	,})
		aadd(aDePara,{"U01_NUMSEQ","MIB_CODMAN"	,})
		aadd(aDePara,{"U01_LACREN","MIB_NROLAC"	,})
		aadd(aDePara,{"U01_CORLAC","MIB_CORLAC"	,})
		aadd(aDePara,{"U02_BICO","MIB_CODBIC"	,})
		aadd(aDePara,{"U02_ENCANT","MIB_ENCINI"	,})
		aadd(aDePara,{"U02_ENCATU","MIB_ENCFIM"	,})*/
	
	ElseIf cAlias == "DH8" //AADD(aTabMigracao, { .F.,  "DH8", "MIB", "Manutenções e Lacres"                   })
		aadd(aDePara,{"DH8_FILIAL","MIB_FILIAL"	,})
		aadd(aDePara,{"DH8_DATA","MIB_DATA"		,})
		aadd(aDePara,{"DH8_NROLAC","MIB_NROLAC"	,})
		aadd(aDePara,{"DH8_CORLAC","MIB_CORLAC"	,})
		aadd(aDePara,{"DH8_MOTIVO","MIB_MOTIVO"	,})
		aadd(aDePara,{"DH8_CDSIMP","MIB_CDSIMP"	,})
		aadd(aDePara,{"DH8_CDINST","MIB_CDINST"	,})
		aadd(aDePara,{"DH8_STATUS","MIB_STATUS"	,})
		aadd(aDePara,{"DH8_BOMBA","MIB_CODBOM"	,})
		aadd(aDePara,{"DH8_BICO","MIB_CODBIC"	,})

	ElseIf cAlias == "LLI" //AADD(aTabMigracao, { .F.,  "LLI"        , "MIC"    , "Cadastro de Bicos da Bombas"            })
		aadd(aDePara,{"LLI_FILIAL","MIC_FILIAL"	,})
		aadd(aDePara,{"LLI_BICO","MIC_CODBIC"	,})
		aadd(aDePara,{"LLI_BOMBA","MIC_CODBOM"	,})
		aadd(aDePara,{"LLI_TANQUE","MIC_CODTAN"	,})
		aadd(aDePara,{"LLI_NLOGIC","MIC_NLOGIC"	,})
		aadd(aDePara,{"LLI_SERBOM","MIC_SERBIC"	,})
		aadd(aDePara,{"LLI_MODBOM","MIC_MODBIC"	,})
		aadd(aDePara,{"LLI_LADO","MIC_LADO"		,})
		aadd(aDePara,{"LLI_STATUS","MIC_STATUS"	,})
		aadd(aDePara,{"LLI_HOST","MIC_XHOST"	,})
		aadd(aDePara,{"LLI_MILHAO","MIC_XMILHA"	,})
		aadd(aDePara,{"LLI_CONCEN","MIC_XCONCE"	,})
		aadd(aDePara,{"LLI_DTDESA","MIC_XDTDES"	,})
		aadd(aDePara,{"LLI_DTATIV","MIC_XDTATI"	,})
		if LLI->(FieldPos("LLI_BABMAN")) > 0
			aadd(aDePara,{"LLI_BABMAN","MIC_XBABMA"	,})
		endif

	ElseIf cAlias == "LLG" //AADD(aTabMigracao, { .F.,  "LLG"        , "MID"    , "Leitura dos Abastecimentos"             })
		aadd(aDePara,{"LLG_FILIAL","MID_FILIAL"	,})
		aadd(aDePara,{"LLG_CODIGO","MID_CODABA"	,})
		aadd(aDePara,{"LLG_SEQUE","MID_SEQUE"	,})
		aadd(aDePara,{"LLG_CODBIT","MID_CODBIT"	,})
		aadd(aDePara,{"LLG_CONDEA","MID_CONDEA"	,})
		aadd(aDePara,{"LLG_TANQUE","MID_CODTAN"	,})
		aadd(aDePara,{"LLG_BOMBA","MID_CODBOM"	,})
		aadd(aDePara,{"LLG_LADO","MID_LADBOM"	,})
		aadd(aDePara,{"LLG_CODBIA","MID_CODBIC"	,})
		aadd(aDePara,{"LLG_NLOGIC","MID_NLOGIC"	,})
		aadd(aDePara,{"LLG_IDVEND","MID_RFID"	,})
		aadd(aDePara,{"LLG_CHECKS","MID_CHECKS"	,})
		aadd(aDePara,{"LLG_PAFMD5","MID_PAFMD5"	,})
		aadd(aDePara,{"LLG_PDV","MID_PDV"		,})
		aadd(aDePara,{"LLG_NUM","MID_NUMORC"	,})
		aadd(aDePara,{"LLG_DTBASE","MID_DTBASE"	,})
		aadd(aDePara,{"LLG_DATACO","MID_DATACO"	,"LLG_DATACO",})
		aadd(aDePara,{"LLG_HORACO","MID_HORACO"	,})
		aadd(aDePara,{"LLG_TOTAL","MID_TOTAPA"	,})
		aadd(aDePara,{"LLG_QTDLT","MID_LITABA"	,})
		aadd(aDePara,{"LLG_VLUNIT","MID_PREPLI"	,})
		aadd(aDePara,{"LLG_ENCLEF","MID_ENCINI"	,})
		aadd(aDePara,{"LLG_NENCER","MID_ENCFIN"	,})
		aadd(aDePara,{"LLG_LEITUR","MID_LEITUR"	,})
		aadd(aDePara,{"LLG_SITUA","MID_SITUA"	,})
		aadd(aDePara,{"LLG_PROD","MID_XPROD"	,})
		aadd(aDePara,{"LLG_CONCEN","MID_XCONCE"	,})
		aadd(aDePara,{"LLG_XDIVER","MID_XDIVER"	,})
		aadd(aDePara,{"LLG_XMANUT","MID_XMANUT"	,})
		if LLG->(FieldPos("LLG_XOPERA")) > 0
			aadd(aDePara,{"LLG_XOPERA","MID_XOPERA"	,})
		endif

	ElseIf cAlias == "SL2" //AADD(aTabMigracao, { .F.,  "SL2"        , "SL2"    , "Itens Orçamento"                        })
		aadd(aDePara,{"R_E_C_N_O_","R_E_C_N_O_"	,})
		aadd(aDePara,{"L2_LEGCOD","L2_MIDCOD"	,})
		aadd(aDePara,{"L2_EMISSAO","L2_EMISSAO"	,"L2_EMISSAO"})
		if SL2->(Fieldpos("L2_BICO")) > 0
			aadd(aDePara,{"L2_BICO","L2_MICCOD"	,})
		Endif
	EndIf

Return aDePara

Static Function xPergunte()

    Local aPergs 		:= {}
    Local aRetPar       := {}
    Local lRet          := .T.

    aAdd(aPergs,{1,"Data: "	,STOD("        ") ,""	,".T."	,""	,	,60	 ,.F.})
    
    If !ParamBox(aPergs,"Migração",@aRetPar,{|| .T.})
        lRet   := .F.
    EndIf

Return lRet
