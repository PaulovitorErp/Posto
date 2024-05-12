#INCLUDE "TOTVS.CH"
#INCLUDE "TOPCONN.CH"
#INCLUDE "Protheus.ch"
#INCLUDE "AP5MAIL.CH"

/*/{Protheus.doc} STFAbastecimentosPendentes
Verifica a existencia de abasteciemntos pendentes e dispara e-mail para contas especificas.

@author Pablo Cavalcante
@since 06/09/2019
@version 1.0

@return ${return}, ${return_description}

@param cEmp, characters, empresa
@param cFil, characters, filial

@type function
/*/
Function U_STFAbast(cEmp,cFil)

Local cQry := ""
Local aAbastecimentos := {}
Local aColunas := {}
Local aTemp := {}
Local nX := 0
Local cWfCargDt := DtoS(Date()) //data do ultimo envio de e-mail com status de carga (erro/pendentes)
Local cWfCargHr := Time() //hora do ultimo envio de e-mail com status de carga (erro/pendentes)
Local nWfCargMn := 120 //invervalo minimo em minutos para envio da análise de status de carga
Local lContinua := .T.
Local nDifDia := 0, nDifMin := 0, cDifHor := ""
Local cUser := '000000'

Default cEmp  := "02"
Default cFil  := "0501"

If IsBlind() //se for rotina automatica

	RpcSetType(3) // Para nao consumir licenças na Threads
	//Reset Environment
	lConect := RpcSetEnv(cEmp, cFil, , ,'FRT',)
	__CUSERID := cUser

	SET DATE FORMAT TO "dd/mm/yyyy"
	SET CENTURY ON
	SET DATE BRITISH

EndIf

//carrega os valores dos parametros
cWfCargDt := SuperGetMV( "MV_XDTABAS" , .F./*lHelp*/, DtoS(Date()) ) //Data do ultimo envio de e-mail com status de abastecimentos (erro/pendentes)
cWfCargHr := SuperGetMV( "MV_XHRABAS" , .F./*lHelp*/, Time() ) //Hora do ultimo envio de e-mail com status de abastecimentos (erro/pendentes)
nWfCargMn := SuperGetMV( "MV_XMNABAS" , .F./*lHelp*/, 120 ) //Invervalo minimo em minutos para envio da análise de status de abastecimentos

//calcula quantos minutos passou da data/hora do ultimo envio até a data/hora atual...
nDifDia	:= Iif(Date()>StoD(cWfCargDt),DateDiffDay(StoD(cWfCargDt),Date()),0)
nDifMin	:= Iif(nDifDia>0,nDifDia*24*60,0)
cDifHor	:= ElapTime(cWfCargHr,Time())
nDifMin	+= Iif(Time()>cWfCargHr,Hrs2Min(Val(SubStr(cDifHor,1,2)))+Val(SubStr(cDifHor,4,2)),Iif(nDifDia>0,(24*60)-(Hrs2Min(Val(SubStr(cDifHor,1,2)))+Val(SubStr(cDifHor,4,2))),0))

//se enviou em um tempo menor que o intervalo minimo não processa novamente
If nDifMin <= nWfCargMn
	lContinua := .F.
EndIf

If lContinua

	aColunas := {"MID_CODBIC", "MID_CODABA", "MID_XPROD", "B1_DESC", "MID_LITABA", "MID_PREPLI", "MID_TOTAPA", "MID_DATACO", "MID_HORACO"}

	// Lista as cargas pendentes
	cQry := "SELECT MID.*, SB1.B1_DESC"+ CRLF
	cQry += " FROM " + RetSQLName("MID") + " MID"+ CRLF
	cQry += " INNER JOIN " + RetSQLName("SB1") + " SB1"+ CRLF
	cQry += " ON (SB1.B1_FILIAL = '"+xFilial("SB1")+"' AND MID.MID_XPROD = SB1.B1_COD AND SB1.D_E_L_E_T_ = ' ')"+ CRLF
	cQry += " WHERE MID.D_E_L_E_T_ = ' '"+ CRLF
	cQry += " AND MID.MID_FILIAL = '"+xFilial("MID")+"'"+ CRLF
	cQry += " AND MID.MID_DATACO < '"+DtoS(Date())+"'"+ CRLF
	cQry += " AND (MID.MID_NUMORC = '"+PadR("P",TamSX3("MID_NUMORC")[1])+"' OR MID.MID_NUMORC = '"+PadR("O",TamSX3("MID_NUMORC")[1])+"')"+ CRLF
	cQry += " ORDER BY MID.MID_FILIAL, MID.MID_DATACO, MID.MID_HORACO"+ CRLF

	If Select("QRYMID") > 0
		QRYMID->( DbCloseArea() )
	EndIf
		
	cQry := ChangeQuery(cQry)
	TcQuery cQry New Alias "QRYMID"

	QRYMID->(DbGoTop())

	While QRYMID->(!EOF())
		
		aTemp := {}
		For nX:=1 to Len(aColunas)
			
			If GetSx3Cache(aColunas[nX],'X3_TIPO') == "C"     //C - Caracter
				aadd(aTemp, QRYMID->&(aColunas[nX]))
			ElseIf GetSx3Cache(aColunas[nX],'X3_TIPO') == "N" //N - Numérico
				aadd(aTemp, AllTrim(Transform(QRYMID->&(aColunas[nX]), GetSx3Cache(aColunas[nX],'X3_PICTURE'))))
			ElseIf GetSx3Cache(aColunas[nX],'X3_TIPO') == "D" //D - Data
				aadd(aTemp, DtoC(StoD(QRYMID->&(aColunas[nX]))))
			ElseIf GetSx3Cache(aColunas[nX],'X3_TIPO') == "M" //M - Memo
				aadd(aTemp, QRYMID->&(aColunas[nX]))
			ElseIf GetSx3Cache(aColunas[nX],'X3_TIPO') == "L" //L - Lógico
				aadd(aTemp, ".F.")
			EndIf
			
		Next nX
		
		Aadd(aAbastecimentos, aTemp)

		QRYMID->(DbSkip())
	EndDo
	QRYMID->( DbCloseArea() )

	If Len(aAbastecimentos) > 0
		EnvMail(aColunas,aAbastecimentos)
	EndIf

	RpcClearEnv()
	DbCloseAll()

EndIf
    
Return

//
// Envia status da carga por E-mail
//
Static function EnvMail(aColunas,aAbastecimentos)

	Local lRet := ""
	Local xHTM := ""
	Local nX := 0, nY := 0
	Local cAssunto	:= "Abastecimentos NAO BAIXADOS na data de origem."
	Local cPara := AllTrim(GetMV("MV_LJEMLAD",,"minhaconta@servername.com.br"))

	xHTM += '<!DOCTYPE html>' 
	xHTM += '<html>' 
	xHTM += '<head>' 
	xHTM += '<style>' 
	xHTM += 'table, th, td {' 
	xHTM += 	'border: 1px solid black;' 
	xHTM += '}' 
	xHTM += 'th, td {' 
	xHTM += 	'padding: 5px;' 
	xHTM += 	'text-align: left;' 
	xHTM += '}' 
	
	xHTM += '</style>' 
	xHTM += '</head>' 
	xHTM += '<body>' 

	SM0->(DbSetOrder(1))
	SM0->(DbSeek(cEmpAnt+cFilAnt))
	
	xHTM += '<h2>Grupo: ' + AllTrim(cEmpAnt) + ' - Filial: ' + AllTrim(cFilAnt) + '</h2>'
	xHTM += '<h2>Empresa: ' + AllTrim(SM0->M0_NOME) + ' / ' + AllTrim(SM0->M0_NOMECOM) + '</h2>'
	xHTM += '<br>'
	xHTM += '<h2>Lista de abastecimentos NÃO BAIXADOS na data de origem.</h2>'
	xHTM += '<br>'
	xHTM += '<br>'
	xHTM += '<p>Segue a lista de abastecimentos que não formam baixados na data de origem (pendêntes do dia anterior).</p>'
	xHTM += '<p>Estes casos poderão gerar divergência entre a data fiscal e data do LMC.</p>'
	xHTM += '<p>Favor providenciar a baixa imediata.</p>'
	xHTM += '<br>'
	xHTM += '<br>'
	xHTM += '<hr noshade>'
	xHTM += '<br>'
	xHTM += '<br>'
	
	//tabela de abastecimentos
	xHTM += '<table style="width:100%"><caption><strong>Listagem de abastecimentos</strong></caption>' 

	//cabeçalho
	xHTM += '<tr>'
	For nX:=1 to Len(aColunas)
		//xHTM += '<td style="width: '+cValToChar(TamSX3(aColunas[nX])[1]*4)+'px;"><strong>'+FWX3Titulo(aColunas[nX])+'</strong></td>'
		xHTM += '<td style="width: '+cValToChar(TamSX3(aColunas[nX])[1]*3)+'px;"><strong>'+FWX3Titulo(aColunas[nX])+'</strong></td>'
	Next nX
	xHTM += '</tr>'

	//itens
	For nX:=1 to Len(aAbastecimentos)
		xHTM += '<tr>'
		For nY:=1 to Len(aAbastecimentos[nX])
			xHTM += '<td>'+aAbastecimentos[nX][nY]+'</td>'
		Next nY
		xHTM += '</tr>'
	Next nX
	
	xHTM += '</table>'
	
	xHTM += '<br>' 
	xHTM += '<br>' 
	xHTM += '<p>TOTVS - Este e-mail foi enviado automaticamente pelo sistema. Favor não responder.</p>'
	xHTM += '<p>Data: '+DtoC(date())+' - Hora: '+time()+'</p>'
	xHTM += '<br>' 
	
	xHTM += '</body>' 
	xHTM += '</html>'
	
	//tenta enviar utilizando a classe LTpSendMail
	oMail := LTpSendMail():New(cPara, cAssunto, xHTM)
	If IsBlind() //se for rotina automatica
		oMail:SetShedule(.T.)
	EndIf
	//oMail:SetAttachment(cLocal+cFilePrint+".pdf") //para anexar arquivo
	lRet := oMail:Send()
	
	If lRet
		
		PutMvPar("MV_XDTABAS",DtoS(Date()))
		PutMvPar("MV_XHRABAS",Time())

		If !IsBlind() //se nao for rotina automatica
			MsgStop("U_STFAbast: e-mail enviado com sucesso...","OK")
		Else
			//Conout("U_STFAbast: e-mail enviado com sucesso...")
		EndIf
	Else
		//tenta enviar utilizando a static funciont SendMail (abaixo...)
		If lRet := SendMail(cAssunto, xHTM)
			
			PutMvPar("MV_XDTABAS",DtoS(Date()))
			PutMvPar("MV_XHRABAS",Time())

			If !IsBlind() //se nao for rotina automatica
				MsgStop("U_STFAbast: erro ao enviar e-mail...","ERRO")
			Else
				//Conout("U_STFAbast: erro ao enviar e-mail...")
			EndIf
		EndIf
	EndIf

Return lRet

//-------------------------------------------------------------------
/*/{Protheus.doc} SendMail
Função para enviar e-mail do log de validação
@param cAssunto Assunto e-mail
@param cMsg     Mensagem do e-mail
@author  Varejo
@version P11.8
@since   26/04/2013
@return  lRet  E-mail enviado com sucesso
@obs
@sample
/*/
//-------------------------------------------------------------------
Static Function SendMail(cAssunto, cMsg)

Local oMail  		:= NIL         //Objeto do Service de e-mail
Local oMessage  	:= NIL         //Mensagem
Local nErro 		:= 0           //Erro
Local lRet 			:= .T.         //Retorno de execução
Local cSMTPServer	:= GetMV("MV_RELSERV",,"smtp.servername.com.br")  		//SMTP Server
Local cSMTPUser		:= GetMV("MV_RELAUSR",,"minhaconta@servername.com.br") 	//Usuário de autenticação
Local cSMTPPass		:= GetMV("MV_RELAPSW",,"minhasenha")                   	//Senha
Local cMailFrom		:= GetMV("MV_RELFROM",,"minhaconta@servername.com.br")  //Remetente
Local lUseAuth		:= GetMV("MV_RELAUTH",,.T.)                             //Autentica?
Local cPara 		:= GetMV("MV_LJEMLAD",,"minhaconta@servername.com.br")  //Destinatário
LOCAL nSMTPPort 	:= GetMV("MV_PORSMTP",,25)								//Porta
LOCAL lSSL 			:= GetMV("MV_RELSSL ",.F.,.F.)							//SSL?
Local lTLS			:= GetMV("MV_RELTLS ",.F.,.F.)                       	//TLS?
Local nTOUT			:= GetMV("MV_RELTIME",.F.,120)							//Time-Out
Local lVirgula 		:= SuperGetMv("MV_XMAILVI",.F.,.F.)

	DEFAULT cAssunto := ""
	DEFAULT cMsg := ""

	//cMsg := StrTran(StrTran(StrTran(StrTran(StrTran(StrTran(cMsg, ";"), "&", "&amp;"), " ", "&nbsp;"), ">", "&gt;"), "<", "&lt;"), CRLF, "<BR>")

	If !lTLS
		//MailSMTPOn
		CONNECT SMTP SERVER cSMTPServer ACCOUNT cSMTPUser PASSWORD cSMTPPass RESULT lRet
		If 	lRet
			SEND MAIL FROM cMailFrom ;
				TO IIF(lVirgula,StrTran(cPara,";",","),cPara) ;
				SUBJECT cAssunto ;
				BODY cMsg;
				ATTACHMENT ;
				RESULT lRet
			If !lRet
				GET MAIL ERROR cMAilError
				//Conout("Erro no envio do e-mail " + RTrim(cMAilError)) //"Erro no envio do e-mail "
			EndIf
			DISCONNECT SMTP SERVER
		Else
			GET MAIL ERROR cMAilError
			//Conout("Erro na conexão:" +  RTrim(cErro)) //"Erro na conexão:"
		EndIf

	Else

		oMail := TMailManager():New()
		oMail:SetUseSSL(lSSL)
		oMail:SetUseTLS(lTLS)

		nErro := oMail:Init( "", cSMTPServer, cSMTPUser, cSMTPPass, 0, nSMTPPort  )
		If nErro <> 0
			//Conout("Falha ao conectar: " + oMail:getErrorString(nErro)) //"Falha ao conectar: "
			lRet := .F.
		Endif

		If lRet .and. oMail:SetSmtpTimeOut( nTOUT ) != 0
			//Conout("Falha ao definir timeout")
			lRet := .F.
		EndIf

		If lRet
			nErro := oMail:SmtpConnect()
			If nErro <> 0
				//Conout("Falha ao conectar: " + oMail:getErrorString(nErro)) //"Falha ao conectar: "
				lRet := .F.
				oMail:SMTPDisconnect()
			EndIf
		EndIf

		If lRet .and. lUseAuth
			nErro := oMail:SmtpAuth(cSMTPUser ,cSMTPPass)
			If nErro <> 0
				// Recupera erro ...
				cMAilError := oMail:GetErrorString(nErro)
				DEFAULT cMailError := '***UNKNOW***'
				//Conout("Erro de Autenticacao "+str(nErro,4)+' ('+cMAilError+')') //"Erro de Autenticacao "
				lRet := .F.
			EndIf
		EndIf

		If !lRet .and. nErro <> 0

			// Recupera erro
			cMAilError := oMail:GetErrorString(nErro)
			DEFAULT cMailError := '***UNKNOW***'
			//Conout(cMAilError)

			//Conout("Erro de Conexão SMTP "+str(nErro,4)) //"Erro de Conexão SMTP "
			oMail:SMTPDisconnect()

			lRet := .F.

		EndIf

		If lRet
			oMessage := TMailMessage():New()
			oMessage:Clear()
			oMessage:cFrom	:= cMailFrom
			oMessage:cTo	:= cPara
			oMessage:cSubject	:= cAssunto
			oMessage:cBody		:= cMsg
			nErro := oMessage:Send( oMail )

			If nErro <> 0
				xError := oMail:GetErrorString(nErro)
				//Conout("Erro de Envio SMTP "+str(nErro,4)+" ("+xError+")") //"Erro de Envio SMTP "
				lRet := .F.
			EndIf

			oMail:SMTPDisconnect()
			FreeObj(oMessage)
		EndIf

		FreeObj(oMail)

	EndIf

Return lRet
