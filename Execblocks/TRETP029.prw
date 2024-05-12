#INCLUDE "parmtype.ch"
#INCLUDE "TOTVS.CH"
#INCLUDE "TOPCONN.CH"
#INCLUDE "Protheus.ch"
#INCLUDE "AP5MAIL.CH"

/*/{Protheus.doc} LJ7082
Este Ponto de entrada permite a execução de um processo customizado, para que se possa determinar se a venda será processada pelo LjGrvBatch.
Se a venda não for processada e não sofrer nenhuma alteração, ela tentará ser processada na próxima execução do LjGrvBatch.


Motivos para não processar a venda no LjGrvBatch:
L1_SITUA = 'XX' - Venda nao processada pois esta fora do prazo de abertura financeira: MV_DATAFIN.
L1_SITUA = 'YY' - Venda nao processada pois o caixa ja foi conferido.

@author Pablo Nunes
@since 03/01/2020
@version 1.0
@return 	
Retorno Lógico .T. = a venda será processada .F. = a venda não será processada

@type function
/*/
User Function TRETP029()

	Local lRet := .T.
	Local lOk  := .F.
	Local aAreaSL1 := SL1->(GetArea())
	Local aAreaSLW := SLW->(GetArea())
	Local dDataFin := SuperGetMV("MV_DATAFIN",,,SL1->L1_FILIAL)
	Local dDataMov := SL1->L1_EMISNF
	Local cCondicao	:= ""
	Local bCondicao

	Local lMvPosto := SuperGetMv("MV_XPOSTO",.F.,.F.) //Habilita Posto de Combustível (Posto Inteligente).
	//Caso o Posto Inteligente não esteja habilitado não faz nada...
	If !lMvPosto
		Return lRet
	EndIf

	//Conout(">> LJ7082 - INICIO - determinar se a venda será processada pelo LjGrvBatch. - Data / Hora: "+DTOC(Date())+" / "+Time()+" - ["+SL1->L1_DOC+"/"+SL1->L1_SERIE+"]")
//Conout(">> LJ7082 - ProcName(): "+ProcName()+"")

// 27/03/2020: Ingnorar as notas DENEGADAS
	If 'DENEGAD' $ UPPER(SL1->L1_RETSFZ) //L1_KEYNFCE
		RestArea(aAreaSLW)
		RestArea(aAreaSL1)
		//Conout(">> LJ7082 - Ignora as vendas denegadas - L1_RETSFZ: "+SL1->L1_RETSFZ)
		//Conout(">> LJ7082 - FIM - determinar se a venda será processada pelo LjGrvBatch. - Data / Hora: "+DTOC(Date())+" / "+Time()+" - ["+SL1->L1_DOC+"/"+SL1->L1_SERIE+"]")

		Return lRet
	EndIf

//
// Não são permitidas movimentações financeiras com data menores que a data limite de movimentações no financeiro. Verifique o conteúdo do parâmetro MV_DATAFIN
//
	If dDataMov < dDataFin
		lRet := .F.
		RecLock("SL1",.F.)
		SL1->L1_SITUA := "XX" //- Venda nao processada pois esta fora do prazo de abertura financeira: MV_DATAFIN
		SL1->(MsUnlock())
		//Conout(">> LJ7082 - L1_SITUA -> XX - Venda nao processada pois esta fora do prazo de abertura financeira: MV_DATAFIN")
	Endif

//
// Não permitido gerar movimentação para caixa já conferido
//
	If lRet

		//Posiciona na SLW
		SLW->(DbSetOrder(1)) //LW_FILIAL+LW_PDV+LW_OPERADO+DTOS(LW_DTABERT)+LW_NUMMOV

		cCondicao := "LW_FILIAL = '" + SL1->L1_FILIAL + "' .AND. "
		cCondicao += "LW_OPERADO = '" + PadR(SL1->L1_OPERADO,TamSX3("LW_OPERADO")[1]) + "' .AND. "
		cCondicao += "LW_PDV = '" + PadR(SL1->L1_PDV,TamSX3("LW_PDV")[1]) + "' .AND. "
		cCondicao += "LW_ESTACAO = '" + PadR(SL1->L1_ESTACAO,TamSX3("LW_ESTACAO")[1]) + "' .AND. "
		cCondicao += "LW_NUMMOV = '" + PadR(SL1->L1_NUMMOV,TamSX3("LW_NUMMOV")[1]) + "' "

		// Limpa os filtros da SLW
		SLW->(DbClearFilter())

		// Filtra na SLW
		bCondicao := "{|| " + cCondicao + " }"
		SLW->(DbSetFilter(&bCondicao,cCondicao))

		//Conout(">> LJ7082 - Filtro na SLW...")
		//Conout(">> LJ7082 - cCondicao: " + cCondicao)

		SLW->(DbGoTop())

		//SLW->(DbSeek(xFilial("SLW")+PadR(AllTrim(SL1->L1_PDV),TamSX3("LW_PDV")[1])+SL1->L1_OPERADO+DtoS(SL1->L1_EMISNF)+SL1->L1_NUMMOV))
		lOk := .F.
		While SLW->(!Eof()) .AND. !lOk
			If (DtoS(SL1->L1_EMISNF)+SL1->L1_HORA) >= (DtoS(SLW->LW_DTABERT)+SLW->LW_HRABERT) ;
					.AND. (Empty(DtoS(SLW->LW_DTFECHA)) .or. (DtoS(SL1->L1_EMISNF)+SL1->L1_HORA) <= (DtoS(SLW->LW_DTFECHA)+SLW->LW_HRFECHA))

				//Conout(">> LJ7082 - Encontrou o caixa na SLW...")
				//Conout(">> LJ7082 - cChave := SLW->(LW_FILIAL+LW_PDV+LW_OPERADO+DtoS(LW_DTABERT)+LW_ESTACAO+LW_NUMMOV): " + SLW->(LW_FILIAL+LW_PDV+LW_OPERADO+DtoS(LW_DTABERT)+LW_ESTACAO+LW_NUMMOV))

				lOk := .T.
				Exit //sai do While

			EndIf
			SLW->(DbSkip())
		EndDo

		If lOk
			If !Empty(DtoS(SLW->LW_DTFECHA)) .and. SLW->LW_CONFERE == "1" // 1 - Caixa Conferido / 2 - Conferencia Pendente / 3 - Pendente PDV
				lRet := .F.
				RecLock("SL1",.F.)
				SL1->L1_SITUA := "YY" //- Venda nao processada pois o caixa ja foi conferido
				SL1->(MsUnlock())
				//Conout(">> LJ7082 - L1_SITUA -> YY - Venda nao processada pois o caixa ja foi conferido")
			EndIf
		EndIf

	EndIf

	If !lRet //a venda não será processa, envia e-mail com dados da venda e motivo
		EnvMail(cEmpAnt,SL1->L1_FILIAL)
	EndIf

// Limpa os filtros da SLW
	SLW->(DbClearFilter())

	RestArea(aAreaSLW)
	RestArea(aAreaSL1)

	//Conout(">> LJ7082 - FIM - determinar se a venda será processada pelo LjGrvBatch. - Data / Hora: "+DTOC(Date())+" / "+Time()+" - ["+SL1->L1_DOC+"/"+SL1->L1_SERIE+"]")

Return lRet

//
// Envia status da carga por E-mail
//
Static function EnvMail(cEmpSM0,cFilSM0)

	Local lRet := ""
	Local xHTM := ""
	Local nX := 0, nY := 0
	Local cAssunto	:= "LjGrvBatch - Venda NAO processada: "+SL1->L1_DOC+"/"+SL1->L1_SERIE+"."
	Local cPara := AllTrim(GetMV("MV_LJEMLAD",,"minhaconta@servername.com.br"))
	Local lVirgula := GetMV("MV_XMAILVI",.F.,.F.)

	Local aColunas := {"L1_FILIAL","L1_NUM","L1_DOC","L1_SERIE","L1_EMISNF","L1_HORA","L1_SITUA","L1_STATUS","L1_VLRTOT","L1_KEYNFCE","L1_PDV","L1_OPERADO","L1_ESTACAO","L1_NUMMOV"}
	Local aNotas := {}, aTemp := {}
	
	Default cEmpSM0 := cEmpAnt
	Default cFilSM0 := cFilAnt

	cPara := IIF(lVirgula,StrTran(cPara,";",","),cPara)

	aTemp := {}
	For nX:=1 to Len(aColunas)
		If GetSx3Cache(aColunas[nX],'X3_TIPO') == "C"     //C - Caracter
			aadd(aTemp, SL1->&(aColunas[nX]))
		ElseIf GetSx3Cache(aColunas[nX],'X3_TIPO') == "N" //N - Numérico
			aadd(aTemp, AllTrim(Transform(SL1->&(aColunas[nX]), GetSx3Cache(aColunas[nX],'X3_PICTURE'))))
		ElseIf GetSx3Cache(aColunas[nX],'X3_TIPO') == "D" //D - Data
			aadd(aTemp, DtoC(SL1->&(aColunas[nX])))
		ElseIf GetSx3Cache(aColunas[nX],'X3_TIPO') == "M" //M - Memo
			aadd(aTemp, SL1->&(aColunas[nX]))
		ElseIf GetSx3Cache(aColunas[nX],'X3_TIPO') == "L" //L - Lógico
			aadd(aTemp, ".F.")
		EndIf
	Next nX

	Aadd(aNotas, aTemp)

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

	DbSelectArea("SM0")
	SM0->(DbSetOrder(1))
	SM0->(DbSeek(cEmpSM0 + cFilSM0))

	xHTM += '<h2>Grupo: ' + AllTrim(cEmpSM0) + ' - Filial: ' + AllTrim(cFilSM0) + '</h2>'
	xHTM += '<h2>Empresa: ' + AllTrim(SM0->M0_NOME) + ' / ' + AllTrim(SM0->M0_NOMECOM) + '</h2>'
	xHTM += '<br>'
	xHTM += '<h2>LjGrvBatch - Venda NAO processada: '+SL1->L1_DOC+'/'+SL1->L1_SERIE+'</h2>'
	If SL1->L1_SITUA = 'XX'
		xHTM += '<h2>Motivo: XX - Venda nao processada pois esta fora do prazo de abertura financeira: MV_DATAFIN.</h2>'
	Else
		xHTM += '<h2>Motivo: YY - Venda nao processada pois o caixa ja foi conferido.</h2>'
	EndIf
	xHTM += '<br>'
	xHTM += '<br>'
	xHTM += '<p>Segue os dados da venda que nao pode ser processada.</p>'
	xHTM += '<p>Favor providenciar a correcao...</p>'
	xHTM += '<br>'
	xHTM += '<br>'
	xHTM += '<hr noshade>'
	xHTM += '<br>'
	xHTM += '<br>'

	//tabela com dados da venda
	xHTM += '<table style="width:100%"><caption><strong>Dados da Venda</strong></caption>'

	//cabeçalho
	xHTM += '<tr>'
	For nX:=1 to Len(aColunas)
		//xHTM += '<td style="width: '+cValToChar(TamSX3(aColunas[nX])[1]*4)+'px;"><strong>'+FWX3Titulo(aColunas[nX])+'</strong></td>'
		xHTM += '<td style="width: '+cValToChar(TamSX3(aColunas[nX])[1]*3)+'px;"><strong>'+FWX3Titulo(aColunas[nX])+'</strong></td>'
	Next nX
	xHTM += '</tr>'

	//itens
	For nX:=1 to Len(aNotas)
		xHTM += '<tr>'
		For nY:=1 to Len(aNotas[nX])
			xHTM += '<td>'+aNotas[nX][nY]+'</td>'
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
		//Conout(">> LJ7082 - e-mail enviado com sucesso...")
	Else
		//tenta enviar utilizando a static funciont SendMail (abaixo...)
		//Conout(">> LJ7082 -  tenta enviar utilizando a static funciont SendMail...")
		If lRet := SendMail(cAssunto, xHTM)
			//Conout(">> LJ7082 -  erro ao enviar e-mail...")
		else
			//Conout(">> LJ7082 -  e-mail enviado com sucesso...")
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
	Local lVirgula 		:= GetMV("MV_XMAILVI",.F.,.F.)

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
