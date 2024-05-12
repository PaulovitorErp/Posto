#include "protheus.ch"
#include "topconn.ch"
#include "fwmvcdef.ch"
#include "fweditpanel.ch"

/*/{Protheus.doc} TRETA010
Manutenção LMC
@author TOTVS
@since 17/10/2014
@version P12
@param Nao recebe parametros
@return nulo
/*/

/***********************/
User Function TRETA010()
/***********************/

Local oBrowse

Private aRotina := {}

Private cPerg	:= "TRETM010"
Private cProd	:= ""

oBrowse := FWmBrowse():New()
oBrowse:SetAlias("MIE")
oBrowse:SetDescription("Manutenção LMC")
oBrowse:Activate()

Return Nil

/************************/
Static Function MenuDef()
/************************/

aRotina := {}

ADD OPTION aRotina Title "Visualizar" 			Action "VIEWDEF.TRETA010"	OPERATION 2 ACCESS 0
ADD OPTION aRotina Title "Gerar"    			Action "VIEWDEF.TRETA010"	OPERATION 3 ACCESS 0
ADD OPTION aRotina Title "Excluir"    			Action "VIEWDEF.TRETA010"	OPERATION 5 ACCESS 0
ADD OPTION aRotina Title "Imprimir Pagina"		Action "U_IMPPAG"			OPERATION 4 ACCESS 0
ADD OPTION aRotina Title "Incluir/Alterar Obs."	Action "U_INCOBSPG"			OPERATION 4 ACCESS 0
ADD OPTION aRotina Title "Histórico Vendas LMC"	Action "U_TRETE039(MIE->MIE_DATA,MIE->MIE_CODPRO,.T.)"	OPERATION 4 ACCESS 0
ADD OPTION aRotina Title "Atual. Perdas/Ganhos" Action "U_TRETA10A()" OPERATION 4 ACCESS 0
//ADD OPTION aRotina Title "Atual. Acumulado" Action "U_TRETE39A()" OPERATION 4 ACCESS 0

Return aRotina

/*************************/
Static Function ModelDef()
/*************************/

// Cria a estrutura a ser usada no Modelo de Dados
Local oStruMIE := FWFormStruct(1,"MIE",/*bAvalCampo*/,/*lViewUsado*/ )

Local oModel

// Cria o objeto do Modelo de Dados
oModel := MPFormModel():New("TRETM010",/*bPreValidacao*/,/*bPosValidacao*/,/*bCommit*/,/*bCancel*/ )

// Adiciona ao modelo uma estrutura de formulário de edição por campo
oModel:AddFields("MIEMASTER",/*cOwner*/,oStruMIE)

// Adiciona a chave primaria da tabela principal
oModel:SetPrimaryKey({"MIE_FILIAL","MIE_CODPRO","MIE_DATA"})

// Adiciona a descricao do Componente do Modelo de Dados
oModel:GetModel("MIEMASTER"):SetDescription("Manutenção LMC")

Return oModel

/************************/
Static Function ViewDef()
/************************/

Local nX
// Cria a estrutura a ser usada na View
Local oStruMIE := FWFormStruct(2,"MIE")
Local nQTQLMC := SuperGetMv("MV_XQTQLMC",,20) //Quantidade de tanques para apuração LMC

// Cria um objeto de Modelo de Dados baseado no ModelDef do fonte informado
Local oModel   := FWLoadModel("TRETA010")
Local oView

// Remove campos da estrutura
oStruMIE:RemoveField("MIE_CODBIC")
oStruMIE:RemoveField("MIE_CODTAN")
oStruMIE:RemoveField("MIE_ENCINI")
oStruMIE:RemoveField("MIE_ENCFIN")
oStruMIE:RemoveField("MIE_NOTA")
oStruMIE:RemoveField("MIE_NOTA02")
oStruMIE:RemoveField("MIE_NOTA03")
oStruMIE:RemoveField("MIE_NOTA04")
oStruMIE:RemoveField("MIE_NOTA05")
oStruMIE:RemoveField("MIE_TANQUD")

// Cria o objeto de View
oView := FWFormView():New()

// Define qual o Modelo de dados será utilizado
oView:SetModel(oModel)

// Cria agrupador de campos
oStruMIE:AddGroup('GRUPO01', 'Dados', 				'', 2)
oStruMIE:AddGroup('GRUPO02', 'Acumulados',			'', 2)
oStruMIE:AddGroup('GRUPO03', 'Perdas e Ganhos',		'', 2)
oStruMIE:AddGroup('GRUPO04', 'Estoques Iniciais',	'', 2)
oStruMIE:AddGroup('GRUPO05', 'Estoques Finais',		'', 2)
oStruMIE:AddGroup('GRUPO06', 'Financeiro',			'', 2)
oStruMIE:AddGroup('GRUPO07', 'Outros',				'', 2)

// Colocando todos os campos para o agrupamento 7
oStruMIE:SetProperty( '*' , MVC_VIEW_GROUP_NUMBER, 'GRUPO07')

// Colocando os campos no agrupamento 1
oStruMIE:SetProperty('MIE_DATA' 	, MVC_VIEW_GROUP_NUMBER, 'GRUPO01')
oStruMIE:SetProperty('MIE_CODPRO' 	, MVC_VIEW_GROUP_NUMBER, 'GRUPO01')
oStruMIE:SetProperty('MIE_XDESCR' 	, MVC_VIEW_GROUP_NUMBER, 'GRUPO01')

// Colocando os campos no agrupamento 2
oStruMIE:SetProperty('MIE_ABERT' 	, MVC_VIEW_GROUP_NUMBER, 'GRUPO02')
oStruMIE:SetProperty('MIE_ENTRAD' 	, MVC_VIEW_GROUP_NUMBER, 'GRUPO02')
oStruMIE:SetProperty('MIE_VOLDIS' 	, MVC_VIEW_GROUP_NUMBER, 'GRUPO02')
oStruMIE:SetProperty('MIE_VENDAS' 	, MVC_VIEW_GROUP_NUMBER, 'GRUPO02')
oStruMIE:SetProperty('MIE_AFERIC' 	, MVC_VIEW_GROUP_NUMBER, 'GRUPO02')
oStruMIE:SetProperty('MIE_ESTESC' 	, MVC_VIEW_GROUP_NUMBER, 'GRUPO02')
oStruMIE:SetProperty('MIE_ESTFEC' 	, MVC_VIEW_GROUP_NUMBER, 'GRUPO02')
if GetSx3Cache('MIE_XKARDE',"X3_TIPO")=="N"
	oStruMIE:SetProperty('MIE_XKARDE' 	, MVC_VIEW_GROUP_NUMBER, 'GRUPO02')
endif

// Colocando os campos no agrupamento 3
oStruMIE:SetProperty('MIE_PERDA' 	, MVC_VIEW_GROUP_NUMBER, 'GRUPO03')
oStruMIE:SetProperty('MIE_GANHOS' 	, MVC_VIEW_GROUP_NUMBER, 'GRUPO03')
oStruMIE:SetProperty('MIE_XPERGP' 	, MVC_VIEW_GROUP_NUMBER, 'GRUPO03')

// Colocando os campos no agrupamento 4
for nX := 1 to nQTQLMC
	if MIE->(FieldPos( 'MIE_ESTI'+StrZero(nX,2) ))>0
		oStruMIE:SetProperty('MIE_ESTI'+StrZero(nX,2) 	, MVC_VIEW_GROUP_NUMBER, 'GRUPO04')
	endif
next nX

// Colocando os campos no agrupamento 5
for nX := 1 to nQTQLMC
	if MIE->(FieldPos( 'MIE_VTAQ'+StrZero(nX,2) ))>0
		oStruMIE:SetProperty('MIE_VTAQ'+StrZero(nX,2) 	, MVC_VIEW_GROUP_NUMBER, 'GRUPO05')
	endif
next nX

// Colocando os campos no agrupamento 6
oStruMIE:SetProperty('MIE_VLRITE' 	, MVC_VIEW_GROUP_NUMBER, 'GRUPO06')
oStruMIE:SetProperty('MIE_ACUMUL' 	, MVC_VIEW_GROUP_NUMBER, 'GRUPO06')

//Adiciona no nosso View um controle do tipo FormFields(antiga enchoice)
oView:AddField("VIEW_MIE",oStruMIE,"MIEMASTER")

// Criar "box" horizontal para receber algum elemento da view
oView:CreateHorizontalBox("PAINEL_CABEC", 100)

// Relaciona o ID da View com o "box" para exibicao
oView:SetOwnerView("VIEW_MIE","PAINEL_CABEC")

// Padroniza o layout para 02 colunas
oView:SetViewProperty("MIEMASTER","SETLAYOUT",{FF_LAYOUT_VERT_DESCR_TOP,2})
oView:SetViewProperty("MIEMASTER", "SETCOLUMNSEPARATOR", {10})

// Liga a identificacao do componente
oView:EnableTitleView("VIEW_MIE","Manutenção LMC")

// Função na abertura da tela
oView:SetAfterViewActivate({|oView| (ProcessPag(oView))})

// Define fechamento da tela ao confirmar a operação
oView:SetCloseOnOk( {||.T.} )

Return oView

/********************************/
Static Function ProcessPag(oView)
/********************************/

Local nOperation 	:= oView:GetOperation()
Local oModel	 	:= FWModelActive()
Local oModelMIE  	:= oModel:GetModel("MIEMASTER")

Local lVldCx		:= SuperGetMv("MV_XVLDCXA",.F.,.F.)
Local dData			:= CToD("")
Local lContinua
Local aRetDup		:= {}

If nOperation == 3 //Inclusão

	If !Empty(MV_PAR01)

		dData := BuscaDt(MV_PAR01)

		//Se valida confirmação de caixas
		If lVldCx

			lContinua := VldCxs(dData)

			If !lContinua
				Help( ,, 'Help - GeraLMC',, 'Há caixas a serem confirmados, geração não permitida.', 1, 0 )
				Return .F.
			Endif
		Endif

		aRetDup := DupEnc(dData,MV_PAR01)

		If aRetDup[1] .And. aRetDup[2]
			Help( ,, 'Help - GeraLMC',, 'Verificada duplicidade de encerrantes. Foi necessário ajuste de encerrante.', 1, 0 )
		ElseIf aRetDup[1] .And. !aRetDup[2]
			Help( ,, 'Help - GeraLMC',, 'Verificada duplicidade de encerrantes, onde a quantidade dos respectivos abastecimentos é superior a 1 (um) LT. Necessária verificação manual', 1, 0 )
			Return
		Endif

		cNrLivro 	:= BuscaNr(MV_PAR01,dData)
		cProd 		:= MV_PAR01

		FWMsgRun(,{|| U_TRETE009(dData,cProd,cNrLivro,oModelMIE)},"Aguarde","Processando página LMC...")

		//If Type("__aDados") <> "U"
		//	__aDados :=  Nil
		//Endif

		oView:Refresh()
	Endif
Endif

Return .T.

/*****************************/
Static Function BuscaDt(cProd)
/*****************************/

Local dData	:= dDataBase
Local cQry	:= ""

If Select("QRYLMC") > 0
	QRYLMC->(DbCloseArea())
Endif

cQry := "SELECT MAX(MIE_DATA) AS DT"
cQry += " FROM "+RetSqlName("MIE")+""
cQry += " WHERE D_E_L_E_T_ 	= ' '"
cQry += " AND MIE_FILIAL 	= '"+xFilial("MIE")+"'"
cQry += " AND MIE_CODPRO	= '"+cProd+"'"

cQry := ChangeQuery(cQry)
//MemoWrite("c:\temp\TRETA010.txt",cQry)
TcQuery cQry NEW Alias "QRYLMC"

If QRYLMC->(!EOF())
	If !Empty(QRYLMC->DT)
		dData := SToD(QRYLMC->DT) + 1
	Endif
Endif

If Select("QRYLMC") > 0
	QRYLMC->(DbCloseArea())
Endif

Return dData

/**********************************/
Static Function DupEnc(dData,cProd)
/**********************************/

Local lRet 		:= .F.
Local lAjuste	:= .F.
Local cQry		:= ""
Local aTq		:= {}
Local cTq		:= ""
Local nI
Local nCont		:= 0
Local aAbast	:= {}

If Select("QRYTQ") > 0
	QRYTQ->(dbCloseArea())
Endif

cQry := "SELECT MHZ_CODTAN"
cQry += " FROM "+RetSqlName("MHZ")+""
cQry += " WHERE D_E_L_E_T_ 	<> '*'"
cQry += " AND MHZ_FILIAL	= '"+xFilial("MHZ")+"'"
cQry += " AND MHZ_CODPRO	= '"+cProd+"'"
cQry += " AND ((MHZ_STATUS = '1' AND MHZ_DTATIV <= '"+DToS(dData)+"') OR (MHZ_STATUS = '2' AND MHZ_DTDESA >= '"+DToS(dData)+"'))"
cQry += " ORDER BY 1"

cQry := ChangeQuery(cQry)
//MemoWrite("c:\temp\TRETA010.txt",cQry)
TcQuery cQry NEW Alias "QRYTQ"

While QRYTQ->(!EOF())

	AAdd(aTq,QRYTQ->MHZ_CODTAN)

	QRYTQ->(DbSkip())
EndDo

For nI := 1 To Len(aTq)

	If nI == Len(aTq)
		cTq += "'" + aTq[nI] + "'"
	Else
		cTq += "'" + aTq[nI] + "',"
	Endif
Next

If !Empty(cTq)

	If Select("QRYVEN") > 0
		QRYVEN->(dbCloseArea())
	Endif
	
	cQry := "SELECT MIC_CODTAN, MIC_CODBIC, MIC_NLOGIC, MIC_CODBOM"
	cQry += " FROM "+RetSqlName("MIC")+" "
	cQry += " WHERE D_E_L_E_T_ <> '*'"
	cQry += " AND MIC_FILIAL	= '"+xFilial("MIC")+"'"
	cQry += " AND MIC_CODTAN	IN ("+cTq+")"
	cQry += " AND ((MIC_STATUS = '1' AND MIC_XDTATI <= '"+DToS(dData)+"') OR (MIC_STATUS = '2' AND MIC_XDTDES >= '"+DToS(dData)+"'))"
	cQry += " ORDER BY 3"
	
	cQry := ChangeQuery(cQry)
	//MemoWrite("c:\temp\QRYVEND.txt",cQry)
	TcQuery cQry NEW Alias "QRYVEN"
	
	If QRYVEN->(!EOF())
	
		While QRYVEN->(!EOF()) .And. !lRet
	
			nCont 	:= 0
			aAbast	:= {}
	
			If Select("QRYVERIF") > 0
				QRYVERIF->(DbCloseArea())
			Endif
	
			cQry := "SELECT MAX(MID_ENCFIN) AS ENC"
			cQry += " FROM "+RetSqlName("MID")+""
			cQry += " WHERE D_E_L_E_T_	<> '*'"
			cQry += " AND MID_FILIAL	= '"+xFilial("MID")+"'"
			cQry += " AND MID_XPROD		= '"+cProd+"'"
			cQry += " AND MID_DATACO	= '"+DToS(dData)+"'"
			cQry += " AND MID_CODTAN	= '"+QRYVEN->MIC_CODTAN+"'"
			cQry += " AND MID_CODBIC	= '"+QRYVEN->MIC_CODBIC+"'"
			cQry += " AND LEN(MID_NUMORC)	> 1" //Finalizado
	
			cQry := ChangeQuery(cQry)
			//MemoWrite("c:\temp\QRYVERIF.txt",cQry)
			TcQuery cQry NEW Alias "QRYVERIF"
	
			While QRYVERIF->(!EOF())
	
				AAdd(aAbast,{1,QRYVERIF->ENC,QRYVEN->MIC_CODTAN,QRYVEN->MIC_CODBIC})
				nCont++
	
				QRYVERIF->(DbSkip())
			EndDo
	
			If nCont > 1
				lRet := .T.
			Endif
	
			If !lRet
	
				nCont 	:= 0
				aAbast	:= {}
	
				If Select("QRYVERIF") > 0
					QRYVERIF->(DbCloseArea())
				Endif
	
				cQry := "SELECT MIN(MID_ENCFIN) AS ENC"
				cQry += " FROM "+RetSqlName("MID")+""
				cQry += " WHERE D_E_L_E_T_ 	<> '*'"
				cQry += " AND MID_FILIAL	= '"+xFilial("MID")+"'"
				cQry += " AND MID_XPROD		= '"+cProd+"'"
				cQry += " AND MID_DATACO	= '"+DToS(dData)+"'"
				cQry += " AND MID_CODTAN	= '"+QRYVEN->MIC_CODTAN+"'"
				cQry += " AND MID_CODBIC	= '"+QRYVEN->MIC_CODBIC+"'"
				cQry += " AND LEN(MID_NUMORC)	> 1" //Finalizado
	
				cQry := ChangeQuery(cQry)
				//MemoWrite("c:\temp\QRYVERIF.txt",cQry)
				TcQuery cQry NEW Alias "QRYVERIF"
	
				While QRYVERIF->(!EOF())
	
					AAdd(aAbast,{2,QRYVERIF->ENC,QRYVEN->MIC_CODTAN,QRYVEN->MIC_CODBIC})
					nCont++
	
					QRYVERIF->(DbSkip())
				EndDo
	
				If nCont > 1
					lRet := .T.
				Endif
	
				If !lRet
	
					nCont 	:= 0
					aAbast	:= {}
	
					If Select("QRYVERIF") > 0
						QRYVERIF->(DbCloseArea())
					Endif
	
					cQry := "SELECT (MID_ENCFIN - MID_LITABA) AS ENC"
					cQry += " FROM "+RetSqlName("MID")+""
					cQry += " WHERE D_E_L_E_T_ 	<> '*'"
					cQry += " AND MID_FILIAL	= '"+xFilial("MID")+"'"
					cQry += " AND MID_XPROD		= '"+cProd+"'"
					cQry += " AND MID_DATACO	= '"+DToS(dData)+"'"
					cQry += " AND MID_CODTAN	= '"+QRYVEN->MIC_CODTAN+"'"
					cQry += " AND MID_CODBIC	= '"+QRYVEN->MIC_CODBIC+"'"
					cQry += " AND LEN(MID_NUMORC)	> 1" //Finalizado
					cQry += " AND MID_ENCFIN 	= (SELECT MIN(MID_ENCFIN)"
					cQry += " 						FROM "+RetSqlName("MID")+""
					cQry += " 						WHERE D_E_L_E_T_ 	<> '*'"
					cQry += " 						AND MID_FILIAL		= '"+xFilial("MID")+"'"
					cQry += " 						AND MID_XPROD		= '"+cProd+"'"
					cQry += " 						AND MID_DATACO		= '"+DToS(dData)+"'"
					cQry += " 						AND MID_CODTAN		= '"+QRYVEN->MIC_CODTAN+"'"
					cQry += " 						AND MID_CODBIC		= '"+QRYVEN->MIC_CODBIC+"'"
					cQry += " 						AND LEN(MID_NUMORC)	> 1 " //Finalizado
					cQry += " )"
	
					cQry := ChangeQuery(cQry)
					//MemoWrite("c:\temp\QRYVERIF.txt",cQry)
					TcQuery cQry NEW Alias "QRYVERIF"
	
					While QRYVERIF->(!EOF())
	
						AAdd(aAbast,{3,QRYVERIF->ENC,QRYVEN->MIC_CODTAN,QRYVEN->MIC_CODBIC})
						nCont++
	
						QRYVERIF->(DbSkip())
					EndDo
	
					If nCont > 1
						lRet := .T.
					Endif
	
					If !lRet
	
						nCont 	:= 0
						aAbast	:= {}
	
						If Select("QRYVERIF") > 0
							QRYVERIF->(DbCloseArea())
						Endif
	
						cQry := "SELECT MAX(MID_ENCFIN) AS ENC"
						cQry += " FROM "+RetSqlName("MID")+""
						cQry += " WHERE D_E_L_E_T_ 	<> '*'"
						cQry += " AND MID_FILIAL	= '"+xFilial("MID")+"'"
						cQry += " AND MID_XPROD		= '"+cProd+"'"
						cQry += " AND MID_DATACO	< '"+DToS(dData)+"'"
						cQry += " AND MID_CODTAN	= '"+QRYVEN->MIC_CODTAN+"'"
						cQry += " AND MID_CODBIC	= '"+QRYVEN->MIC_CODBIC+"'"
						cQry += " AND LEN(MID_NUMORC)	> 1" //Finalizado
	
						cQry := ChangeQuery(cQry)
						//MemoWrite("c:\temp\QRYVERIF.txt",cQry)
						TcQuery cQry NEW Alias "QRYVERIF"
	
						While QRYVERIF->(!EOF())
	
							AAdd(aAbast,{1,QRYVERIF->ENC,QRYVEN->MIC_CODTAN,QRYVEN->MIC_CODBIC})
							nCont++
	
							QRYVERIF->(DbSkip())
						EndDo
	
						If nCont > 1
							lRet := .T.
						Endif
					Endif
				Endif
			Endif
	
			QRYVEN->(DbSkip())
		EndDo
	Endif
Endif

//Necessário ajuste do encerrante
If lRet

	DbSelectArea("MID")

	For nI := 1 To Len(aAbast)

		If !lAjuste

			If Select("QRYVERIF") > 0
				QRYVERIF->(DbCloseArea())
			Endif

			cQry := "SELECT MID.R_E_C_N_O_ AS MIDRECNO, MID.MID_LITABA"
			cQry += " FROM "+RetSqlName("MID")+" MID"
			cQry += " WHERE MID.D_E_L_E_T_	<> '*'"
			cQry += " AND MID.MID_FILIAL	= '"+xFilial("MID")+"'"
			cQry += " AND MID.MID_XPROD		= '"+cProd+"'"
			cQry += " AND MID.MID_DATACO	= '"+DToS(dData)+"'"
			cQry += " AND MID.MID_CODTAN	= '"+aAbast[nI][3]+"'"
			cQry += " AND MID.MID_CODBIC	= '"+aAbast[nI][4]+"'"

			If aAbast[nI][1] == 1 //Novo encerrante
				cQry += " AND MID.MID_ENCFIN	= "+cValToChar(aAbast[nI][2])+""
			ElseIf aAbast[nI][1] == 2 //Encerrante inicial
				cQry += " AND MID.MID_ENCFIN	= "+cValToChar(aAbast[nI][2])+""
			Else //Encerrante - Quantidade
				cQry += " AND MID.MID_ENCFIN - MID.MID_LITABA = "+cValToChar(aAbast[nI][2])+""
			Endif

			cQry := ChangeQuery(cQry)
			//MemoWrite("c:\temp\QRYVERIF.txt",cQry)
			TcQuery cQry NEW Alias "QRYVERIF"

			If QRYVERIF->(!EOF())

				While QRYVERIF->(!EOF())

					If QRYVERIF->MID_LITABA < 1

						MID->(DbGoTo(QRYVERIF->MIDRECNO))

						RecLock("MID",.F.)
						MID->MID_ENCFIN := MID->MID_ENCFIN + 0.001
						MID->(MsUnlock())

						lAjuste := .T.
						Exit
					Endif

					QRYVERIF->(DbSkip())
				EndDo
			Endif
		Endif
	Next nI
Endif

If Select("QRYTQ") > 0
	QRYTQ->(dbCloseArea())
Endif

If Select("QRYVEN") > 0
	QRYVEN->(dbCloseArea())
Endif

If Select("QRYVERIF") > 0
	QRYVERIF->(DbCloseArea())
Endif

Return {lRet,lAjuste}

/***********************************/
Static Function BuscaNr(cProd,dData)
/***********************************/

Local cId		:= ""
Local cNr 		:= ""

Local cQry		:= ""
Local cQry2		:= ""

Local cTpSeq 	:= SuperGetMv("MV_XTPLIVR",,"2")

If Select("QRYLIVRO") > 0
	QRYLIVRO->(dbCloseArea())
Endif

cQry := "SELECT UB4_CODIGO AS COD"
cQry += " FROM "+RetSqlName("UB4")+""
cQry += " WHERE D_E_L_E_T_ 	<> '*'"
cQry += " AND UB4_FILIAL 	= '"+xFilial("UB4")+"'"
cQry += " AND UB4_PROD	 	= '"+cProd+"'"
cQry += " AND UB4_COMPET	= '"+SubStr(DToS(dData),5,2)+SubStr(DToS(dData),1,4)+"'"

cQry := ChangeQuery(cQry)
//MemoWrite("c:\temp\TRETA010.txt",cQry)
TcQuery cQry NEW Alias "QRYLIVRO"

If QRYLIVRO->(!EOF())
	cId := QRYLIVRO->COD
Else

	DbSelectArea("UB4")
	UB4->(dbSetOrder(1)) //UB4_FILIAL+UB4_CODIGO

	If Select("QRYNROLMC") > 0
		QRYNROLMC->(dbCloseArea())
	Endif

	cQry2 := "SELECT MAX(UB4_CODIGO) AS COD"
	cQry2 += " FROM "+RetSqlName("UB4")+""
	cQry2 += " WHERE D_E_L_E_T_ 	<> '*'"
	cQry2 += " AND UB4_FILIAL 	= '"+xFilial("UB4")+"'"

	If cTpSeq == "2" //sequencial por produto
		cQry2 += " AND UB4_PROD	 	= '"+cProd+"'"
	Endif

	cQry2 := ChangeQuery(cQry2)
	//MemoWrite("c:\temp\TRETA010.txt",cQry)
	TcQuery cQry2 NEW Alias "QRYNROLMC"

	If QRYNROLMC->(!EOF())

		If !Empty(QRYNROLMC->COD)

			If UB4->(dbSeek(xFilial("UB4")+QRYNROLMC->COD))

				If cTpSeq == "2" //sequencial por produto

					If UB4->UB4_COMPET == SubStr(DToS(dData),5,2)+SubStr(DToS(dData),1,4)
						cId := QRYNROLMC->COD
					Else
						cId := GetSX8Num("UB4","UB4_CODIGO")
						cNr := Soma1(UB4->UB4_NUMERO)

						RecLock("UB4",.T.)
						UB4->UB4_FILIAL := xFilial("UB4")
						UB4->UB4_CODIGO	:= cId
						UB4->UB4_PROD	:= cProd
						UB4->UB4_DESCRI	:= Posicione("SB1",1,xFilial("SB1")+cProd,"B1_DESC")
						UB4->UB4_NUMERO	:= cNr
						UB4->UB4_COMPET	:= SubStr(DToS(dData),5,2)+SubStr(DToS(dData),1,4)
						UB4->UB4_PAGINA	:= "S" //Sequencial
						UB4->(MsUnlock())

						ConfirmSX8()
					Endif
				Else
					If UB4->UB4_PROD == cProd .And. UB4->UB4_COMPET == SubStr(DToS(dData),5,2)+SubStr(DToS(dData),1,4)
						cId := QRYNROLMC->COD
					Else
						cId := GetSX8Num("UB4","UB4_CODIGO")
						cNr := Soma1(UB4->UB4_NUMERO)

						RecLock("UB4",.T.)
						UB4->UB4_FILIAL := xFilial("UB4")
						UB4->UB4_CODIGO	:= cId
						UB4->UB4_PROD	:= cProd
						UB4->UB4_DESCRI	:= Posicione("SB1",1,xFilial("SB1")+cProd,"B1_DESC")
						UB4->UB4_NUMERO	:= cNr
						UB4->UB4_COMPET	:= SubStr(DToS(dData),5,2)+SubStr(DToS(dData),1,4)
						UB4->UB4_PAGINA	:= "S" //Sequencial
						UB4->(MsUnlock())

						ConfirmSX8()
					Endif
				Endif
			Endif
		Else
			cId := GetSX8Num("UB4","UB4_CODIGO")
			cNr := "000001"

			RecLock("UB4",.T.)
			UB4->UB4_FILIAL := xFilial("UB4")
			UB4->UB4_CODIGO	:= cId
			UB4->UB4_PROD	:= cProd
			UB4->UB4_DESCRI	:= Posicione("SB1",1,xFilial("SB1")+cProd,"B1_DESC")
			UB4->UB4_NUMERO	:= cNr
			UB4->UB4_COMPET	:= SubStr(DToS(dData),5,2)+SubStr(DToS(dData),1,4)
			UB4->UB4_PAGINA	:= "S" //Sequencial
			UB4->(MsUnlock())

			ConfirmSX8()
		Endif
	Else
		cId := GetSX8Num("UB4","UB4_CODIGO")
		cNr := "000001"

		RecLock("UB4",.T.)
		UB4->UB4_FILIAL := xFilial("UB4")
		UB4->UB4_CODIGO	:= cId
		UB4->UB4_PROD	:= cProd
		UB4->UB4_DESCRI	:= Posicione("SB1",1,xFilial("SB1")+cProd,"B1_DESC")
		UB4->UB4_NUMERO	:= cNr
		UB4->UB4_COMPET	:= SubStr(DToS(dData),5,2)+SubStr(DToS(dData),1,4)
		UB4->UB4_PAGINA	:= "S" //Sequencial
		UB4->(MsUnlock())

		ConfirmSX8()
	Endif
Endif

If Select("QRYLIVRO") > 0
	QRYLIVRO->(dbCloseArea())
Endif

If Select("QRYNROLMC") > 0
	QRYNROLMC->(dbCloseArea())
Endif

Return cId

/****************************/
Static Function VldCxs(dData)
/****************************/

Local lRet := .T.

Local cQry	:= ""

If Select("QRYCXS") > 0
	QRYCXS->(DbCloseArea())
Endif

cQry := "SELECT R_E_C_N_O_"
cQry += " FROM "+RetSqlName("SLW")+""
cQry += " WHERE D_E_L_E_T_ 	<> '*'"
cQry += " AND LW_FILIAL 	= '"+xFilial("SLW")+"'"
cQry += " AND LW_DTABERT	= '"+DToS(dData)+"'"
cQry += " AND LW_CONFERE	= '2'" //Não conferido
cQry += " ORDER BY 1"

cQry := ChangeQuery(cQry)
//MemoWrite("c:\temp\TRETA010.txt",cQry)
TcQuery cQry NEW Alias "QRYCXS"

If QRYCXS->(!EOF())
	lRet :=  .F.
Endif

If Select("QRYCXS") > 0
	QRYCXS->(DbCloseArea())
Endif

Return lRet

/*********************/
User Function ImpPag()
/*********************/

U_TRETR005(MIE->MIE_DATA,MIE->MIE_CODPRO,MIE->MIE_NRLIVR)

Return

/**********************/
User Function IncObsPg()
/**********************/

Local oSay1, oSay2
Local oObs
Local oButton1, oButton2

Local cObs := IIF(!Empty(MIE->MIE_OBS),MIE->MIE_OBS,Space(60))

Static oDlg

DEFINE MSDIALOG oDlg TITLE "Incluir/Alterar Observação" From 000,000 TO 095,545 PIXEL

@ 007, 005 SAY oSay1 PROMPT "Observação:" SIZE 035, 007 OF oDlg COLORS CLR_BLUE, 16777215 PIXEL
@ 005, 045 MSGET oObs VAR cObs SIZE 220, 010 OF oDlg COLORS 0, 16777215 PIXEL Picture "@!"

//Linha horizontal
@ 020, 005 SAY oSay2 PROMPT Repl("_",260) SIZE 260, 007 OF oDlg COLORS CLR_GRAY, 16777215 PIXEL

@ 031, 180 BUTTON oButton1 PROMPT "Confirmar" SIZE 040, 010 OF oDlg ACTION GrvObsPg(cObs) PIXEL
@ 031, 225 BUTTON oButton2 PROMPT "Fechar" SIZE 040, 010 OF oDlg ACTION oDlg:End() PIXEL

ACTIVATE MSDIALOG oDlg CENTERED

Return

/*****************************/
Static Function GrvObsPg(cObs)
/*****************************/

If Empty(cObs)
	Help( ,, 'Help - GeraLMC',, 'Campo Observação obritatório.', 1, 0 )
	Return
Else
	RecLock("MIE",.F.)
	MIE->MIE_OBS := cObs
	MIE->(MsUnlock())

	Help( ,, 'Help - GeraLMC',, 'Obsevação incluída com sucesso.', 1, 0 )

	oDlg:End()
Endif

Return

/********************************/
User Function DetPag(dData,cProd)
/********************************/

U_TRETE010(dData,cProd)

Return

/********************************/
User Function TRETA10A()
/********************************/

	Local aArea := GetArea()
	Local aAreaMIE := MIE->(GetArea())
	Local cTmPerda	:= SuperGetMv("MV_XTMPERD",,"")
	Local cTmGanho	:= SuperGetMv("MV_XTMGANH",,"")
	//Ajustar o Tipo de Movimento com o campo Valorizado (F5_VAL) igual a "N" 
	//-> Se preenchido com N, indica que o custo da movimentação será valorizado automaticamente.	
	
	Local cQry		:= ""
	Local aParamBox := {}

	Private aParam := Array(4)

	aParam[01] := xFilial("MIE")
	aParam[02] := Space(TamSX3("B1_COD")[1])
	aParam[03] := STOD("")
	aParam[04] := STOD("")

	aAdd(aParamBox,{1,"Filial  ", aParam[01], "@!",'.T.',"SM0" ,'.T.', 40, .F.})
	aAdd(aParamBox,{1,"Produto ", aParam[02], "","","SB1","",0,.F.})
	aAdd(aParamBox,{1,"Data de ", aParam[03], "",'.T.',"" ,'.T.', 50, .T.})
	aAdd(aParamBox,{1,"Data ate", aParam[04], "",'.T.',"" ,'.T.', 50,  .T.})

	If ParamBox(aParamBox,"PARÂMETROS",@aParam)

		If Select("QRYMIE") > 0
			QRYMIE->(DbCloseArea())
		Endif

		cQry := "SELECT MIE.R_E_C_N_O_ MIERECNO"
		cQry += " FROM "+RetSqlName("MIE") + " MIE"
		cQry += " WHERE MIE.D_E_L_E_T_ = ' '"
		cQry += " AND (MIE.MIE_GANHOS > 0 OR MIE.MIE_PERDA > 0)"
		cQry += " AND NOT EXISTS (SELECT 1 FROM "+RetSqlName("SD3")+" SD3 "
		cQry += " WHERE SD3.D_E_L_E_T_ = ' ' "
		cQry += " AND SD3.D3_FILIAL = MIE.MIE_FILIAL "
		cQry += " AND SD3.D3_EMISSAO = MIE.MIE_DATA "
		cQry += " AND SD3.D3_COD = MIE.MIE_CODPRO "
		cQry += " AND (SD3.D3_TM = '"+cTmPerda+"' OR SD3.D3_TM = '"+cTmGanho+"')"
		cQry += " AND SD3.D3_ESTORNO <> 'S'" //filtrando não estornados
		cQry += " )"

		cQry += " AND MIE.MIE_FILIAL = '"+aParam[01]+"'"
		cQry += " AND MIE.MIE_CODPRO = '"+aParam[02]+"'"
		cQry += " AND MIE.MIE_DATA >= '"+DtoS(aParam[03])+"' AND MIE.MIE_DATA <= '"+DtoS(aParam[04])+"'"

		cQry += " ORDER BY MIE_FILIAL, MIE_CODPRO, MIE_DATA"

		cQry := ChangeQuery(cQry)
		TcQuery cQry NEW Alias "QRYMIE"

		DbSelectArea("MIE")

		While QRYMIE->(!EOF())
			MIE->(DbGoTo(QRYMIE->MIERECNO))
			dData := MIE->MIE_DATA
			cProd := MIE->MIE_CODPRO
			
			FWMsgRun(,{|| AtuPerdGanh(dData,cProd)},"Aguarde","Reprocessando perdas e ganhos do LMC...")

			QRYMIE->(DbSkip())
		EndDo

		QRYMIE->(DbCloseArea())

	EndIf

	RestArea(aAreaMIE)
	RestArea(aArea)
Return

Static Function AtuPerdGanh(dData,cProd)

	Local nX
	Local aPerda := {}
	Local aGanho := {}
	Local nPerda := 0
	Local nGanho := 0
	Local aFech  := {}
	Local nQTQLMC := SuperGetMv("MV_XQTQLMC",,20) //Quantidade de tanques para apuração LMC
	Local oLMC 

	oLMC := TLmcLib():New(cProd, dData)
    oLMC:SetTRetVen(2) //1=Vlr Total Vendas; 2=Array Dados; 3=Qtd Registros
	oLMC:SetDRetVen({"_TANQUE", "_BICO", "_NLOGIC", "_BOMBA", "_FECH", "_ABERT", "_AFERIC", "_VDBICO","_VDSUMMID"})

    //retorna dados de vendas
	aDadosVe := oLMC:RetVen(.T.) //via query

	//estorna os movimentos de perda e ganho
	U_TRM010ES(dData, cProd)

	//atualizando estoques finais
	//inicio com os estoques iniciais
	For nX := 1 To nQTQLMC
		if MIE->(FieldPos( 'MIE_ESTI'+StrZero(nX,2) ))>0 
			aadd(aFech, {StrZero(nX,2),  MIE->&("MIE_ESTI" + StrZero(nX,2)) } )
		else
			aadd(aFech, {StrZero(nX,2),  0 } )
		endif
	Next nX
	//subtraio as vendas do tanque
	For nX := 1 To len(aDadosVe)
		aFech[val(aDadosVe[nX][1])][2] -= aDadosVe[nX][8]
	Next nX
	//somo as entradas
	MHZ->(DbSetOrder(3)) //MHZ_FILIAL+MHZ_CODPRO+MHZ_LOCAL
	SF4->(DbSetOrder(1)) //F4_FILIAL+F4_CODIGO
	SF1->(DbSetOrder(1)) //F1_FILIAL+F1_DOC+F1_SERIE+F1_FORNECE+F1_LOJA+F1_TIPO
	SD1->(DbSetOrder(6)) //D1_FILIAL+DTOS(D1_DTDIGIT)+D1_NUMSEQ
	If SD1->(DbSeek(xFilial("SD1")+DToS(dData)))
		While SD1->(!EOF()) .And. SD1->D1_FILIAL+DToS(SD1->D1_DTDIGIT) == xFilial("SD1")+DToS(dData)
			If SD1->D1_TIPO $ "N/D" //Diferente de Complementos e Beneficiamento
				If SF1->(DbSeek(xFilial("SF1")+SD1->D1_DOC+SD1->D1_SERIE+SD1->D1_FORNECE+SD1->D1_LOJA))
					If SF1->F1_XLMC == "S" //Considera LMC
						If SF4->(DbSeek(xFilial("SF4")+SD1->D1_TES))
							If SF4->F4_ESTOQUE == "S" //Movimenta estoque
								If SD1->D1_COD == cProd
									//Tanque relacionado
									If MHZ->(DbSeek(xFilial("MHZ")+SD1->D1_COD+SD1->D1_LOCAL))
										While MHZ->(!Eof()) .AND. MHZ->MHZ_FILIAL + MHZ->MHZ_CODPRO + MHZ->MHZ_LOCAL == xFilial("MHZ")+SD1->D1_COD+SD1->D1_LOCAL
											//If MHZ->MHZ_STATUS == "1" //Ativo
											if ((MHZ->MHZ_STATUS == '1' .AND. MHZ->MHZ_DTATIV <= dData) .OR. (MHZ->MHZ_STATUS == '2' .AND. MHZ->MHZ_DTDESA >= dData))
												aFech[val(MHZ->MHZ_CODTAN)][2] += SD1->D1_QUANT
												EXIT //sai laço MHZ
											Endif
											MHZ->(DbSkip())
										Enddo
									EndIf
								Endif
							Endif
						Endif
					Endif
				Endif
			Endif

			SD1->(DbSkip())
		EndDo
	EndIf

	//monto perdas e ganhos
	For nX := 1 To nQTQLMC
		If MIE->(FieldPos( 'MIE_VTAQ'+StrZero(nX,2) ))>0
			If MIE->&("MIE_VTAQ" + StrZero(nX,2)) <> aFech[nX][2]
				If aFech[nX][2] - MIE->&("MIE_VTAQ" + StrZero(nX,2)) > 0
					aAdd(aPerda,{StrZero(nX,2), aFech[nX][2] - MIE->&("MIE_VTAQ" + StrZero(nX,2)) })
					nPerda += aFech[nX][2] - MIE->&("MIE_VTAQ" + StrZero(nX,2)) 
				Else
					aAdd(aGanho,{StrZero(nX,2),MIE->&("MIE_VTAQ" + StrZero(nX,2)) - aFech[nX][2] })
					nGanho += MIE->&("MIE_VTAQ" + StrZero(nX,2)) - aFech[nX][2]
				Endif
			Endif
		Endif
	Next nX

	Begin Transaction

	If Len(aPerda) > 0
		U_TRM010GE(1,dData, cProd, aPerda)
	Endif

	If Len(aGanho) > 0
		U_TRM010GE(2,dData, cProd, aGanho)
	Endif

	End Transaction
	
	/*

	DbSelectArea("MIE")
    MIE->(DbSetOrder(1)) //MIE_FILIAL+MIE_CODPRO+DTOS(MIE_DATA)+MIE_CODTAN+MIE_CODBIC
    If MIE->(DbSeek( xFilial("MIE")+cProd+DTOS(dData) ))

		Reclock("MIE", .F.)

		If nGanho > nPerda
			MIE->MIE_GANHOS := nGanho - nPerda
			MIE->MIE_PERDA := 0
		Else
			MIE->MIE_GANHOS := 0
			MIE->MIE_PERDA := nPerda - nGanho
		Endif

		MIE->MIE_ESTFEC := MIE->MIE_ESTESC + MIE->MIE_GANHOS - MIE->MIE_PERDA

		//atualizo percentual de perda/ganho
		If MIE->(FieldPos("MIE_PERCGP")) > 0
			MIE->MIE_PERCGP := Abs(((MIE->MIE_ESTFEC - MIE->MIE_ESTESC) / MIE->MIE_ESTESC) * 100)
		Endif
	
		MIE->(MsUnlock())

	EndIf

	*/

Return
